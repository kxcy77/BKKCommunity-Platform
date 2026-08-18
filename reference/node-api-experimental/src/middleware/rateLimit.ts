import rateLimit from 'express-rate-limit'

const message = (action: string) => ({
  error: { message: `Too many ${action} attempts. Please try again in 15 minutes.` },
})

/** Strict limiter for auth endpoints — 5 requests per 15 minutes per IP */
export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: message('sign-in'),
  skipSuccessfulRequests: false,
})

/** Slightly more generous limiter for forgot-password */
export const forgotPasswordLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 3,
  standardHeaders: true,
  legacyHeaders: false,
  message: message('password-reset'),
})

/** Limits guesses against a six-digit reset code. */
export const resetPasswordLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: message('password-reset'),
})

export const contactLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: { message: 'Too many contact messages. Please try again later.' } },
})

/** Global fallback — 100 requests per 15 minutes per IP */
export const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: { message: 'Too many requests. Please slow down.' } },
})
