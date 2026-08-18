import crypto from 'crypto'
import { NextFunction, Request, Response } from 'express'
import jwt, { JwtPayload } from 'jsonwebtoken'
import { config } from '../config'
import prisma from '../db'

const ACCESS_TOKEN_TTL_SECONDS = 8 * 60 * 60

export interface AuthRequest extends Request {
  memberId?: number
  sessionTokenId?: string
  isAdmin?: boolean
}

interface AccessTokenPayload extends JwtPayload {
  sub: string
  jti: string
  typ: 'access'
}

export async function createAuthToken(memberId: number): Promise<string> {
  const tokenId = crypto.randomUUID()
  const expiresAt = new Date(Date.now() + ACCESS_TOKEN_TTL_SECONDS * 1000)

  await prisma.authSession.create({ data: { memberId, tokenId, expiresAt } })

  return jwt.sign(
    { sub: String(memberId), typ: 'access' },
    config.JWT_SECRET,
    {
      algorithm: 'HS256',
      audience: config.JWT_AUDIENCE,
      expiresIn: ACCESS_TOKEN_TTL_SECONDS,
      issuer: config.JWT_ISSUER,
      jwtid: tokenId,
    }
  )
}

function unauthorized(res: Response): void {
  res.status(401).json({ error: { message: 'Session expired. Please sign in again.' } })
}

async function authenticate(req: AuthRequest): Promise<{ memberId: number; tokenId: string }> {
  const header = req.headers.authorization
  if (!header?.startsWith('Bearer ')) throw new jwt.JsonWebTokenError('Missing bearer token')

  const payload = jwt.verify(header.slice(7), config.JWT_SECRET, {
    algorithms: ['HS256'],
    audience: config.JWT_AUDIENCE,
    issuer: config.JWT_ISSUER,
  }) as AccessTokenPayload

  const memberId = Number(payload.sub)
  if (!Number.isSafeInteger(memberId) || memberId <= 0 || payload.typ !== 'access' || !payload.jti) {
    throw new jwt.JsonWebTokenError('Invalid access-token claims')
  }

  const session = await prisma.authSession.findUnique({ where: { tokenId: payload.jti } })
  if (!session || session.memberId !== memberId || session.revokedAt || session.expiresAt <= new Date()) {
    throw new jwt.JsonWebTokenError('Revoked or expired session')
  }

  return { memberId, tokenId: payload.jti }
}

export async function optionalAuthMemberId(req: Request): Promise<number | null> {
  if (!req.headers.authorization) return null
  try {
    return (await authenticate(req as AuthRequest)).memberId
  } catch (error) {
    if (error instanceof jwt.JsonWebTokenError || error instanceof jwt.TokenExpiredError) return null
    throw error
  }
}

export async function requireAuth(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
  try {
    const identity = await authenticate(req)
    req.memberId = identity.memberId
    req.sessionTokenId = identity.tokenId
    next()
  } catch (error) {
    if (error instanceof jwt.JsonWebTokenError || error instanceof jwt.TokenExpiredError) {
      unauthorized(res)
      return
    }
    next(error)
  }
}

export async function requireAdmin(req: AuthRequest, res: Response, next: NextFunction): Promise<void> {
  try {
    const identity = await authenticate(req)
    const member = await prisma.member.findUnique({
      where: { id: identity.memberId },
      select: { isAdmin: true },
    })
    if (!member?.isAdmin) {
      res.status(403).json({ error: { message: 'Admin access required.' } })
      return
    }
    req.memberId = identity.memberId
    req.sessionTokenId = identity.tokenId
    req.isAdmin = true
    next()
  } catch (error) {
    if (error instanceof jwt.JsonWebTokenError || error instanceof jwt.TokenExpiredError) {
      unauthorized(res)
      return
    }
    next(error)
  }
}
