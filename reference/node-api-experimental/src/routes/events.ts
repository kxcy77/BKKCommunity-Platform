import { Router, Request, Response } from 'express'
import prisma from '../db'
import { optionalAuthMemberId, requireAuth, AuthRequest } from '../middleware/auth'
import { validate, AttendanceSchema } from '../middleware/validate'
import { asyncHandler } from '../middleware/asyncHandler'
import { isDemonstrationEvent } from '../domain/eventSafety'

export const eventsRouter = Router()

const eventDto = (
  e: { id: number; title: string; description: string; startAt: Date; endAt: Date; location: string; directions: string | null; category: string; colourHex: string },
  isAttending: boolean
) => ({
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

// GET /events
eventsRouter.get('/', asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const category = typeof req.query.category === 'string' ? req.query.category : undefined
  const events = await prisma.event.findMany({
    where: category ? { category } : undefined,
    orderBy: { startAt: 'asc' },
  })

  // Resolve attendance if the caller is authenticated
  let attendingIds = new Set<number>()
  const memberId = await optionalAuthMemberId(req)
  if (memberId) {
    const rows = await prisma.attendance.findMany({
      where: { memberId, status: 'attending' },
      select: { eventId: true },
    })
    attendingIds = new Set(rows.map(r => r.eventId))
  }

  res.json({ data: events.map(e => eventDto(e, attendingIds.has(e.id))) })
}))

// GET /events/:id
eventsRouter.get('/:id', asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const idStr = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id
  const id = parseInt(idStr, 10)
  const event = await prisma.event.findUnique({ where: { id } })
  if (!event) { res.status(404).json({ error: { message: 'Event not found.' } }); return }
  res.json({ data: eventDto(event, false) })
}))

// PUT /events/:id/attendance  (requires auth)
eventsRouter.put('/:id/attendance', requireAuth, validate(AttendanceSchema), asyncHandler(async (req: AuthRequest, res: Response): Promise<void> => {
  const idStr = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id
  const eventId = parseInt(idStr, 10)
  const { status } = req.body  // 'attending' | 'cancelled'
  const event = await prisma.event.findUnique({ where: { id: eventId } })
  if (!event) { res.status(404).json({ error: { message: 'Event not found.' } }); return }
  if (status === 'attending' && isDemonstrationEvent(event)) {
    res.status(422).json({ error: { code: 'demo_event', message: 'This demonstration event cannot accept attendance.' } })
    return
  }

  await prisma.attendance.upsert({
    where: { memberId_eventId: { memberId: req.memberId!, eventId } },
    update: { status },
    create: { memberId: req.memberId!, eventId, status },
  })
  res.json({ data: { event_id: eventId, status } })
}))
