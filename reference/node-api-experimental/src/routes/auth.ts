import { Router, Request, Response } from 'express'
import bcrypt from 'bcryptjs'
import crypto from 'crypto'
import { config } from '../config'
import prisma from '../db'
import { createAuthToken, requireAuth, AuthRequest } from '../middleware/auth'
import { authLimiter, forgotPasswordLimiter, resetPasswordLimiter } from '../middleware/rateLimit'
import {
  validate,
  RegisterSchema,
  LoginSchema,
  ForgotPasswordSchema,
  ResetPasswordSchema,
} from '../middleware/validate'
import { sendPasswordResetEmail } from '../services/email'
import { asyncHandler } from '../middleware/asyncHandler'

export const authRouter = Router()

const MAX_FAILED_ATTEMPTS = 5
const LOCKOUT_MINUTES = 15
const RESET_CODE_TTL_MS = 15 * 60 * 1000

const RESET_RESPONSE = 'If an account exists with that email, a 6-digit password reset code has been sent to your email inbox.'

function hashResetCode(memberId: number, email: string, code: string): string {
  return crypto
    .createHmac('sha256', config.RESET_CODE_PEPPER)
    .update(`${memberId}:${email}:${code}`)
    .digest('hex')
}

const memberDto = (m: {
  id: number
  fullName: string
  email: string
  phone: string | null
  notificationsEnabled: boolean
  eventRemindersEnabled: boolean
  discountAlertsEnabled: boolean
}) => ({
  id: m.id,
  full_name: m.fullName,
  email: m.email,
  phone: m.phone,
  notifications_enabled: m.notificationsEnabled,
  event_reminders_enabled: m.eventRemindersEnabled,
  discount_alerts_enabled: m.discountAlertsEnabled,
})

// POST /auth/register  — rate limited + validated
authRouter.post(
  '/register',
  authLimiter,
  validate(RegisterSchema),
  asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const { full_name, email, phone, password } = req.body

    const existing = await prisma.member.findUnique({ where: { email } })
    if (existing) {
      res.status(409).json({ error: { message: 'An account with that email already exists.' } })
      return
    }

    const passwordHash = await bcrypt.hash(password, 12)
    const member = await prisma.member.create({
      data: { fullName: full_name, email, phone: phone ?? null, passwordHash },
    })

    const token = await createAuthToken(member.id)
    res.status(201).json({ data: { user: memberDto(member), token } })
  })
)

// POST /auth/login  — rate limited + validated + account lockout
authRouter.post(
  '/login',
  authLimiter,
  validate(LoginSchema),
  asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const { email, password } = req.body

    const member = await prisma.member.findUnique({ where: { email } })

    // Generic error — never reveal whether the email exists
    const invalidError = { error: { message: 'Incorrect email or password.' } }

    if (!member) {
      res.status(401).json(invalidError)
      return
    }

    // Check account lockout
    if (member.lockedUntil && member.lockedUntil > new Date()) {
      const minutesLeft = Math.ceil((member.lockedUntil.getTime() - Date.now()) / 60000)
      res.status(429).json({
        error: {
          message: `Account temporarily locked after too many failed attempts. Try again in ${minutesLeft} minute${minutesLeft === 1 ? '' : 's'}.`,
        },
      })
      return
    }

    const passwordMatch = await bcrypt.compare(password, member.passwordHash)

    if (!passwordMatch) {
      const newAttempts = member.failedAttempts + 1
      const shouldLock = newAttempts >= MAX_FAILED_ATTEMPTS
      await prisma.member.update({
        where: { id: member.id },
        data: {
          failedAttempts: newAttempts,
          lockedUntil: shouldLock
            ? new Date(Date.now() + LOCKOUT_MINUTES * 60 * 1000)
            : null,
        },
      })

      if (shouldLock) {
        res.status(429).json({
          error: {
            message: `Too many failed attempts. Account locked for ${LOCKOUT_MINUTES} minutes.`,
          },
        })
        return
      }

      const remaining = MAX_FAILED_ATTEMPTS - newAttempts
      res.status(401).json({
        error: {
          message:
            remaining > 0
              ? `Incorrect email or password. ${remaining} attempt${remaining === 1 ? '' : 's'} remaining before lockout.`
              : 'Incorrect email or password.',
        },
      })
      return
    }

    // Success — reset failed attempts
    await prisma.member.update({
      where: { id: member.id },
      data: { failedAttempts: 0, lockedUntil: null },
    })

    const token = await createAuthToken(member.id)
    res.json({ data: { user: memberDto(member), token } })
  })
)

// DELETE /auth/session — revoke this device's current session.
authRouter.delete('/session', requireAuth, asyncHandler(async (req: AuthRequest, res: Response) => {
  await prisma.authSession.updateMany({
    where: { tokenId: req.sessionTokenId, revokedAt: null },
    data: { revokedAt: new Date() },
  })
  res.json({ data: { message: 'Signed out.' } })
}))

// POST /auth/forgot-password  — stricter rate limit + validated
authRouter.post(
  '/forgot-password',
  forgotPasswordLimiter,
  validate(ForgotPasswordSchema),
  asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const cleanEmail = req.body.email

    const member = await prisma.member.findUnique({ where: { email: cleanEmail } })
    // Keep this response uniform for unknown accounts to avoid account enumeration.
    if (!member) {
      res.json({ data: { message: RESET_RESPONSE } })
      return
    }

    const issuedAt = new Date()
    let code = ''
    let resetId: number | undefined

    try {
      // A new request invalidates every previous unused code for this account.
      await prisma.passwordReset.updateMany({
        where: { memberId: member.id, usedAt: null },
        data: { usedAt: issuedAt },
      })

      // randomInt uses cryptographically secure randomness. The token column stores
      // only an HMAC of the code, never the code a member enters.
      for (let attempt = 0; attempt < 3; attempt += 1) {
        code = crypto.randomInt(0, 1_000_000).toString().padStart(6, '0')
        try {
          const reset = await prisma.passwordReset.create({
            data: {
              memberId: member.id,
              codeHash: hashResetCode(member.id, cleanEmail, code),
              expiresAt: new Date(Date.now() + RESET_CODE_TTL_MS),
            },
          })
          resetId = reset.id
          break
        } catch (error: unknown) {
          if ((error as { code?: string }).code !== 'P2002' || attempt === 2) throw error
        }
      }

      if (!resetId) throw new Error('Could not create a password-reset code.')
      await sendPasswordResetEmail({ to: cleanEmail, code })
    } catch (error) {
      // Never leave a code usable when sending it failed.
      if (resetId) {
        await prisma.passwordReset.update({
          where: { id: resetId },
          data: { usedAt: new Date() },
        }).catch(() => undefined)
      }
      // Keep the public response identical for known and unknown accounts.
      console.error('[PASSWORD RESET] Delivery failed.', { errorName: (error as Error)?.name })
      res.json({ data: { message: RESET_RESPONSE } })
      return
    }

    res.json({ data: { message: RESET_RESPONSE } })
  })
)

// POST /auth/reset-password  — validated
authRouter.post(
  '/reset-password',
  resetPasswordLimiter,
  validate(ResetPasswordSchema),
  asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const { email, token, password } = req.body
    const member = await prisma.member.findUnique({ where: { email }, select: { id: true } })

    if (!member) {
      res.status(400).json({ error: { message: 'This reset code is invalid or has expired. Request a new code and try again.' } })
      return
    }

    const resetCodeHash = hashResetCode(member.id, email, token)

    const reset = await prisma.passwordReset.findUnique({ where: { codeHash: resetCodeHash } })
    if (!reset || reset.usedAt || reset.expiresAt < new Date()) {
      const activeReset = await prisma.passwordReset.findFirst({
        where: { memberId: member.id, usedAt: null, expiresAt: { gt: new Date() } },
        orderBy: { createdAt: 'desc' },
      })
      if (activeReset) {
        await prisma.passwordReset.update({
          where: { id: activeReset.id },
          data: activeReset.failedAttempts >= 4
            ? { failedAttempts: { increment: 1 }, usedAt: new Date() }
            : { failedAttempts: { increment: 1 } },
        })
      }
      res.status(400).json({ error: { message: 'This reset code is invalid or has expired. Request a new code and try again.' } })
      return
    }

    const passwordHash = await bcrypt.hash(password, 12)
    const completedAt = new Date()
    await prisma.$transaction([
      prisma.member.update({
        where: { id: reset.memberId },
        data: { passwordHash, failedAttempts: 0, lockedUntil: null },
      }),
      prisma.passwordReset.update({ where: { id: reset.id }, data: { usedAt: completedAt } }),
      prisma.passwordReset.updateMany({
        where: { memberId: reset.memberId, usedAt: null, id: { not: reset.id } },
        data: { usedAt: completedAt },
      }),
      prisma.authSession.updateMany({
        where: { memberId: reset.memberId, revokedAt: null },
        data: { revokedAt: completedAt },
      }),
    ])

    res.json({ data: { message: 'Your password has been updated.' } })
  })
)
