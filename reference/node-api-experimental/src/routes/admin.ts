import { Router, Response } from 'express'
import prisma from '../db'
import { requireAdmin, AuthRequest } from '../middleware/auth'
import {
  AdminDiscountSchema,
  AdminEventSchema,
  AdminRoleSchema,
  AdminServiceSchema,
  validate,
} from '../middleware/validate'
import { asyncHandler } from '../middleware/asyncHandler'
import { notifyNewDiscount } from '../services/notificationJobs'

export const adminRouter = Router()

const parseId = (param: string | string[]): number =>
  parseInt(Array.isArray(param) ? param[0] : param, 10)

const audit = (adminMemberId: number, action: string, entityType: string, entityId?: number) =>
  prisma.adminAuditLog.create({ data: { adminMemberId, action, entityType, entityId } })

// All admin routes require admin token
adminRouter.use(requireAdmin)
adminRouter.param('id', (req, res, next, value) => {
  const id = Number(value)
  if (!Number.isSafeInteger(id) || id <= 0) {
    res.status(400).json({ error: { message: 'A positive numeric record ID is required.' } })
    return
  }
  next()
})

// ─── EVENTS ──────────────────────────────────────────────────────────────────

adminRouter.get('/events', asyncHandler(async (_req: AuthRequest, res: Response): Promise<void> => {
  const events = await prisma.event.findMany({ orderBy: { startAt: 'asc' } })
  const counts = await prisma.attendance.groupBy({
    by: ['eventId'],
    where: { status: 'attending' },
    _count: { eventId: true },
  })
  const countMap = new Map(counts.map(c => [c.eventId, c._count.eventId]))
  res.json({ data: events.map(e => ({ ...e, rsvp_count: countMap.get(e.id) ?? 0 })) })
}))

adminRouter.post('/events', validate(AdminEventSchema), asyncHandler(async (req: AuthRequest, res: Response): Promise<void> => {
  const { title, description, startAt, endAt, location, directions, category, colourHex } = req.body
  if (!title || !description || !startAt || !endAt || !location || !category) {
    res.status(400).json({ error: { message: 'Missing required fields.' } }); return
  }
  const event = await prisma.event.create({
    data: { title, description, startAt: new Date(startAt), endAt: new Date(endAt), location, directions: directions || null, category, colourHex: colourHex || '#315C24' }
  })
  await audit(req.memberId!, 'create', 'event', event.id)
  res.status(201).json({ data: event })
}))

adminRouter.put('/events/:id', validate(AdminEventSchema), asyncHandler(async (req: AuthRequest, res: Response): Promise<void> => {
  const id = parseId(req.params.id)
  const { title, description, startAt, endAt, location, directions, category, colourHex } = req.body
  const event = await prisma.event.update({
    where: { id },
    data: { title, description, startAt: startAt ? new Date(startAt) : undefined, endAt: endAt ? new Date(endAt) : undefined, location, directions: directions || null, category, colourHex }
  })
  await audit(req.memberId!, 'update', 'event', event.id)
  res.json({ data: event })
}))

adminRouter.delete('/events/:id', asyncHandler(async (req: AuthRequest, res: Response): Promise<void> => {
  const id = parseId(req.params.id)
  await prisma.event.delete({ where: { id } })
  await audit(req.memberId!, 'delete', 'event', id)
  res.json({ data: { deleted: true } })
}))

// ─── DISCOUNTS ───────────────────────────────────────────────────────────────

adminRouter.get('/discounts', asyncHandler(async (_req: AuthRequest, res: Response): Promise<void> => {
  const discounts = await prisma.discount.findMany({ orderBy: { storeName: 'asc' } })
  res.json({ data: discounts })
}))

adminRouter.post('/discounts', validate(AdminDiscountSchema), asyncHandler(async (req: AuthRequest, res: Response): Promise<void> => {
  const { storeName, title, details, eligibility, claimInstructions, category, validFrom, validUntil } = req.body
  if (!storeName || !title || !details || !eligibility || !claimInstructions || !category) {
    res.status(400).json({ error: { message: 'Missing required fields.' } }); return
  }
  const discount = await prisma.discount.create({
    data: { storeName, title, details, eligibility, claimInstructions, category, validFrom: validFrom ? new Date(validFrom) : null, validUntil: validUntil ? new Date(validUntil) : null }
  })
  await audit(req.memberId!, 'create', 'discount', discount.id)
  res.status(201).json({ data: discount })
  void notifyNewDiscount(discount).catch(error => {
    console.error('[NOTIFICATION JOB] New-discount delivery failed.', { errorName: (error as Error)?.name })
  })
}))

adminRouter.put('/discounts/:id', validate(AdminDiscountSchema), asyncHandler(async (req: AuthRequest, res: Response): Promise<void> => {
  const id = parseId(req.params.id)
  const { storeName, title, details, eligibility, claimInstructions, category, validFrom, validUntil } = req.body
  const discount = await prisma.discount.update({
    where: { id },
    data: { storeName, title, details, eligibility, claimInstructions, category, validFrom: validFrom ? new Date(validFrom) : null, validUntil: validUntil ? new Date(validUntil) : null }
  })
  await audit(req.memberId!, 'update', 'discount', discount.id)
  res.json({ data: discount })
}))

adminRouter.delete('/discounts/:id', asyncHandler(async (req: AuthRequest, res: Response): Promise<void> => {
  const id = parseId(req.params.id)
  await prisma.discount.delete({ where: { id } })
  await audit(req.memberId!, 'delete', 'discount', id)
  res.json({ data: { deleted: true } })
}))

// ─── SERVICES ────────────────────────────────────────────────────────────────

adminRouter.get('/services', asyncHandler(async (_req: AuthRequest, res: Response): Promise<void> => {
  const services = await prisma.localService.findMany({ orderBy: [{ type: 'asc' }, { name: 'asc' }] })
  res.json({ data: services })
}))

adminRouter.post('/services', validate(AdminServiceSchema), asyncHandler(async (req: AuthRequest, res: Response): Promise<void> => {
  const { type, name, address, phone, directions, openingHours } = req.body
  if (!type || !name || !address || !phone) {
    res.status(400).json({ error: { message: 'Missing required fields.' } }); return
  }
  const service = await prisma.localService.create({
    data: { type, name, address, phone, directions: directions || null, openingHours: openingHours || null }
  })
  await audit(req.memberId!, 'create', 'local-service', service.id)
  res.status(201).json({ data: service })
}))

adminRouter.put('/services/:id', validate(AdminServiceSchema), asyncHandler(async (req: AuthRequest, res: Response): Promise<void> => {
  const id = parseId(req.params.id)
  const { type, name, address, phone, directions, openingHours } = req.body
  const service = await prisma.localService.update({
    where: { id },
    data: { type, name, address, phone, directions: directions || null, openingHours: openingHours || null }
  })
  await audit(req.memberId!, 'update', 'local-service', service.id)
  res.json({ data: service })
}))

adminRouter.delete('/services/:id', asyncHandler(async (req: AuthRequest, res: Response): Promise<void> => {
  const id = parseId(req.params.id)
  await prisma.localService.delete({ where: { id } })
  await audit(req.memberId!, 'delete', 'local-service', id)
  res.json({ data: { deleted: true } })
}))

// ─── MEMBERS ─────────────────────────────────────────────────────────────────

adminRouter.get('/members', asyncHandler(async (_req: AuthRequest, res: Response): Promise<void> => {
  const members = await prisma.member.findMany({
    select: { id: true, fullName: true, email: true, phone: true, isAdmin: true, createdAt: true },
    orderBy: { createdAt: 'desc' }
  })
  res.json({ data: members })
}))

adminRouter.patch('/members/:id/admin', validate(AdminRoleSchema), asyncHandler(async (req: AuthRequest, res: Response): Promise<void> => {
  const id = parseId(req.params.id)
  const { isAdmin } = req.body
  if (!isAdmin && id === req.memberId) {
    res.status(409).json({ error: { message: 'You cannot remove your own administrator access.' } })
    return
  }
  if (!isAdmin) {
    const activeAdminCount = await prisma.member.count({ where: { isAdmin: true } })
    if (activeAdminCount <= 1) {
      res.status(409).json({ error: { message: 'At least one administrator must remain.' } })
      return
    }
  }
  const member = await prisma.member.update({ where: { id }, data: { isAdmin } })
  await audit(req.memberId!, isAdmin ? 'grant-admin' : 'revoke-admin', 'member', id)
  res.json({ data: { id: member.id, isAdmin: member.isAdmin } })
}))
