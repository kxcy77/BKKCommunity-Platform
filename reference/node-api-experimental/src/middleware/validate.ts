import { z } from 'zod'
import { Request, Response, NextFunction } from 'express'

// ── Reusable field validators ──────────────────────────────────────────────

const emailField = z
  .string({ message: 'Email is required.' })
  .trim()
  .toLowerCase()
  .email('Please enter a valid email address.')
  .max(254, 'Email address is too long.')

const passwordField = z
  .string({ message: 'Password is required.' })
  .min(8, 'Password must be at least 8 characters.')
  .max(128, 'Password must be no more than 128 characters.')
  .regex(/[A-Za-z]/, 'Password must contain at least one letter.')
  .regex(/[0-9]/, 'Password must contain at least one number.')

const nameField = z
  .string({ message: 'Name is required.' })
  .trim()
  .min(2, 'Name must be at least 2 characters.')
  .max(120, 'Name must be no more than 120 characters.')

const phoneField = z
  .string()
  .trim()
  .max(30, 'Phone number is too long.')
  .optional()
  .nullable()

// ── Request schemas ────────────────────────────────────────────────────────

export const RegisterSchema = z.object({
  full_name: nameField,
  email: emailField,
  phone: phoneField,
  password: passwordField,
})

export const LoginSchema = z.object({
  email: emailField,
  password: z.string({ message: 'Password is required.' }).min(1, 'Password is required.'),
})

export const ForgotPasswordSchema = z.object({
  email: emailField,
})

export const ResetPasswordSchema = z.object({
  email: emailField,
  token: z
    .string({ message: 'Reset code is required.' })
    .regex(/^\d{6}$/, 'Enter the 6-digit reset code from your email.'),
  password: passwordField,
})

export const UpdateProfileSchema = z.object({
  full_name: nameField,
  email: emailField,
  phone: phoneField,
})

export const UpdatePreferencesSchema = z.object({
  notifications_enabled: z.boolean().optional().default(true),
  event_reminders_enabled: z.boolean().optional().default(true),
  discount_alerts_enabled: z.boolean().optional().default(true),
})

export const ContactSchema = z.object({
  name: nameField,
  email: emailField,
  message: z
    .string({ message: 'Message is required.' })
    .min(10, 'Message must be at least 10 characters.')
    .max(3000, 'Message must be no more than 3000 characters.')
    .transform(v => v.trim()),
})

export const AttendanceSchema = z.object({
  status: z.enum(['attending', 'cancelled']),
})

export const FcmTokenSchema = z.object({
  fcm_token: z.string({ message: 'fcm_token is required.' }).min(20).max(512),
  platform: z.enum(['android', 'ios']).default('android'),
  notifications_enabled: z.boolean().optional().default(true),
})

export const TestPushSchema = z.object({
  title: z.string().trim().min(1).max(120).optional(),
  body: z.string().trim().min(1).max(500).optional(),
  event_id: z.coerce.number().int().positive().optional(),
})

const requiredText = (label: string, max: number) =>
  z.string({ message: `${label} is required.` }).trim().min(1, `${label} is required.`).max(max)

const optionalText = (max: number) => z.string().trim().max(max).optional().nullable()
const optionalDate = z.union([z.string().datetime({ offset: true }), z.literal(''), z.null()]).optional()

export const AdminEventSchema = z.object({
  title: requiredText('Title', 200),
  description: requiredText('Description', 5000),
  startAt: z.string().datetime({ offset: true }),
  endAt: z.string().datetime({ offset: true }),
  location: requiredText('Location', 255),
  directions: optionalText(2000),
  category: requiredText('Category', 100),
  colourHex: z.string().regex(/^#[0-9A-Fa-f]{6}$/).default('#315C24'),
}).refine(data => new Date(data.endAt) > new Date(data.startAt), {
  path: ['endAt'],
  message: 'End time must be after the start time.',
})

export const AdminDiscountSchema = z.object({
  storeName: requiredText('Store name', 180),
  title: requiredText('Title', 200),
  details: requiredText('Details', 5000),
  eligibility: requiredText('Eligibility', 2000),
  claimInstructions: requiredText('Claim instructions', 2000),
  category: requiredText('Category', 100),
  validFrom: optionalDate,
  validUntil: optionalDate,
}).refine(data => !data.validFrom || !data.validUntil || new Date(data.validUntil) >= new Date(data.validFrom), {
  path: ['validUntil'],
  message: 'Valid-until date must not be before valid-from date.',
})

export const AdminServiceSchema = z.object({
  type: requiredText('Type', 100),
  name: requiredText('Name', 180),
  address: requiredText('Address', 255),
  phone: requiredText('Phone', 30),
  directions: optionalText(2000),
  openingHours: optionalText(255),
})

export const AdminRoleSchema = z.object({ isAdmin: z.boolean() })

// ── Validation middleware factory ──────────────────────────────────────────

export const validate = <T>(schema: z.ZodSchema<T>) =>
  (req: Request, res: Response, next: NextFunction): void => {
    const result = schema.safeParse(req.body)
    if (!result.success) {
      const message = result.error.issues[0]?.message ?? 'Invalid request.'
      res.status(422).json({ error: { message } })
      return
    }
    req.body = result.data
    next()
  }
