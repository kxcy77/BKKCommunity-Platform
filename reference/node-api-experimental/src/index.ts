import crypto from 'crypto'
import express, { NextFunction, Request, Response } from 'express'
import helmet from 'helmet'
import cors from 'cors'
import { Prisma } from '@prisma/client'
import { config } from './config'
import prisma from './db'
import { authRouter } from './routes/auth'
import { meRouter } from './routes/me'
import { eventsRouter } from './routes/events'
import { discountsRouter } from './routes/discounts'
import { servicesRouter } from './routes/services'
import { contactRouter } from './routes/contact'
import { devicesRouter } from './routes/devices'
import { adminRouter } from './routes/admin'
import { globalLimiter } from './middleware/rateLimit'
import { asyncHandler } from './middleware/asyncHandler'
import { startNotificationScheduler } from './services/notificationJobs'

const app = express()
const PORT = config.PORT

if (config.NODE_ENV === 'production') app.set('trust proxy', 1)

app.use((req, res, next) => {
  const requestId = req.header('x-request-id')?.slice(0, 100) || crypto.randomUUID()
  res.setHeader('x-request-id', requestId)
  next()
})

// ── Security headers (helmet) ──────────────────────────────────────────────
// Sets: X-Content-Type-Options, X-Frame-Options, X-XSS-Protection,
//       Strict-Transport-Security, Referrer-Policy, Content-Security-Policy etc.
app.use(helmet())

// ── CORS — restrict to known origins ──────────────────────────────────────
app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, curl, Postman)
    if (!origin || config.corsOrigins.includes(origin)) {
      callback(null, true)
    } else {
      callback(new Error('Not allowed by CORS'))
    }
  },
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
}))

// ── Body parsing — 20 KB limit blocks payload flooding ────────────────────
app.use(express.json({ limit: '20kb' }))

// ── Global rate limiter (100 req / 15 min per IP) ─────────────────────────
app.use(globalLimiter)

// ── Health check ──────────────────────────────────────────────────────────
app.get('/api/v1/health', (_req, res) => {
  res.json({ status: 'ok' })
})

app.get('/api/v1/ready', asyncHandler(async (_req, res) => {
  await prisma.$queryRaw`SELECT 1`
  res.json({ status: 'ready' })
}))

// ── Routes ────────────────────────────────────────────────────────────────
app.use('/api/v1/auth', authRouter)
app.use('/api/v1/me', meRouter)
app.use('/api/v1/events', eventsRouter)
app.use('/api/v1/discounts', discountsRouter)
app.use('/api/v1/local-services', servicesRouter)
app.use('/api/v1/contact', contactRouter)
app.use('/api/v1/devices', devicesRouter)
app.use('/api/v1/admin', adminRouter)

// ── 404 fallback ──────────────────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ error: { message: 'Not found' } })
})

app.use((error: unknown, req: Request, res: Response, _next: NextFunction) => {
  const requestId = res.getHeader('x-request-id')
  const isBodySyntaxError = error instanceof SyntaxError && 'body' in error

  if (isBodySyntaxError) {
    res.status(400).json({ error: { message: 'Request body contains invalid JSON.', request_id: requestId } })
    return
  }

  if (error instanceof Prisma.PrismaClientKnownRequestError) {
    if (error.code === 'P2002') {
      res.status(409).json({ error: { message: 'That value is already in use.', request_id: requestId } })
      return
    }
    if (error.code === 'P2025') {
      res.status(404).json({ error: { message: 'The requested record was not found.', request_id: requestId } })
      return
    }
  }

  // Never log request bodies, credentials, reset codes, tokens, or personal contact details.
  console.error('[REQUEST FAILED]', { requestId, method: req.method, path: req.path, errorName: (error as Error)?.name })
  res.status(500).json({ error: { message: 'The server could not complete this request.', request_id: requestId } })
})

app.listen(PORT, '0.0.0.0', () => {
  console.log(`BKK API running on http://0.0.0.0:${PORT}`)
  startNotificationScheduler()
})

export default app
