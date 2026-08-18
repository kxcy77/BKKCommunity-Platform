import { z } from 'zod'

const optionalUrl = z.string().url().optional()

const EnvironmentSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().min(1).max(65535).default(8000),
  DATABASE_URL: z.string().startsWith('mysql://', 'DATABASE_URL must be a MySQL connection URL.'),
  JWT_SECRET: z.string().min(32, 'JWT_SECRET must contain at least 32 characters.'),
  JWT_ISSUER: z.string().min(3).default('bkk-community-api'),
  JWT_AUDIENCE: z.string().min(3).default('bkk-community-apps'),
  RESET_CODE_PEPPER: z.string().min(32, 'RESET_CODE_PEPPER must contain at least 32 characters.'),
  CORS_ORIGINS: z.string().default('http://localhost:8080'),
  SMTP_HOST: z.string().min(1).optional(),
  SMTP_PORT: z.coerce.number().int().min(1).max(65535).default(587),
  SMTP_USER: z.string().min(1).optional(),
  SMTP_PASS: z.string().min(1).optional(),
  FROM_EMAIL: z.string().min(3).optional(),
  FIREBASE_SERVICE_ACCOUNT_JSON: z.string().min(2).optional(),
  APP_URL: optionalUrl,
})

const parsed = EnvironmentSchema.safeParse(process.env)

if (!parsed.success) {
  const details = parsed.error.issues.map(issue => `${issue.path.join('.')}: ${issue.message}`).join('; ')
  throw new Error(`Invalid server configuration. ${details}`)
}

const smtpValues = [parsed.data.SMTP_HOST, parsed.data.SMTP_USER, parsed.data.SMTP_PASS, parsed.data.FROM_EMAIL]
const partiallyConfiguredSmtp = smtpValues.some(Boolean) && !smtpValues.every(Boolean)
if (partiallyConfiguredSmtp) {
  throw new Error('SMTP configuration is incomplete. Configure SMTP_HOST, SMTP_USER, SMTP_PASS and FROM_EMAIL together.')
}

export const config = {
  ...parsed.data,
  corsOrigins: parsed.data.CORS_ORIGINS.split(',').map(origin => origin.trim()).filter(Boolean),
  smtpConfigured: smtpValues.every(Boolean),
} as const
