import { Router, Response } from 'express'
import prisma from '../db'
import { requireAuth, AuthRequest } from '../middleware/auth'
import { validate, UpdateProfileSchema, UpdatePreferencesSchema } from '../middleware/validate'
import { asyncHandler } from '../middleware/asyncHandler'
import { isDemonstrationEvent } from '../domain/eventSafety'

export const meRouter = Router()
meRouter.use(requireAuth)

const memberDto = (m: { id: number; fullName: string; email: string; phone: string | null; notificationsEnabled: boolean; eventRemindersEnabled: boolean; discountAlertsEnabled: boolean }) => ({
  id: m.id,
  full_name: m.fullName,
  email: m.email,
  phone: m.phone,
  notifications_enabled: m.notificationsEnabled,
  event_reminders_enabled: m.eventRemindersEnabled,
  discount_alerts_enabled: m.discountAlertsEnabled,
})

const eventDto = (e: { id: number; title: string; description: string; startAt: Date; endAt: Date; location: string; directions: string | null; category: string; colourHex: string }, isAttending: boolean) => ({
  id: e.id,
  title: e.title,
  description: e.description,
  start_at: e.startAt.toISOString(),
  end_at: e.endAt.toISOString(),
  location: e.location,
  directions: e.directions,
  category: e.category,
  colour_hex: e.colourHex,
  is_attending: isAttending,
  is_demo: isDemonstrationEvent(e),
})

// GET /me
meRouter.get('/', asyncHandler(async (req: AuthRequest, res: Response): Promise<void> => {
  const member = await prisma.member.findUnique({ where: { id: req.memberId } })
  if (!member) { res.status(404).json({ error: { message: 'Account not found.' } }); return }
  res.json({ data: memberDto(member) })
}))

// PATCH /me
meRouter.patch('/', validate(UpdateProfileSchema), asyncHandler(async (req: AuthRequest, res: Response): Promise<void> => {
  const { full_name, email, phone } = req.body
  if (!full_name || !email) { res.status(422).json({ error: { message: 'Name and email are required.' } }); return }
  const member = await prisma.member.update({
    where: { id: req.memberId },
    data: { fullName: full_name, email, phone: phone ?? null },
  })
  res.json({ data: memberDto(member) })
}))

// DELETE /me
meRouter.delete('/', asyncHandler(async (req: AuthRequest, res: Response): Promise<void> => {
  await prisma.member.delete({ where: { id: req.memberId } })
  res.json({ data: { message: 'Account deleted.' } })
}))

// PATCH /me/notification-preferences
meRouter.patch('/notification-preferences', validate(UpdatePreferencesSchema), asyncHandler(async (req: AuthRequest, res: Response): Promise<void> => {
  const { notifications_enabled, event_reminders_enabled, discount_alerts_enabled } = req.body
  const member = await prisma.member.update({
    where: { id: req.memberId },
    data: {
      notificationsEnabled: notifications_enabled ?? true,
      eventRemindersEnabled: event_reminders_enabled ?? true,
      discountAlertsEnabled: discount_alerts_enabled ?? true,
    },
  })
  res.json({ data: memberDto(member) })
}))

// GET /me/attendance
meRouter.get('/attendance', asyncHandler(async (req: AuthRequest, res: Response): Promise<void> => {
  const rows = await prisma.attendance.findMany({
    where: { memberId: req.memberId, status: 'attending' },
    include: { event: true },
    orderBy: { event: { startAt: 'asc' } },
  })
  res.json({ data: rows.map(r => eventDto(r.event, true)) })
}))
