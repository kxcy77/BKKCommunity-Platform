import prisma from '../db'
import { pushConfigured, sendPushToMember } from './push'

const FIFTEEN_MINUTES_MS = 15 * 60 * 1_000

export async function notifyNewDiscount(discount: { id: number; storeName: string; title: string }): Promise<void> {
  if (!pushConfigured()) return
  const members = await prisma.member.findMany({
    where: { notificationsEnabled: true, discountAlertsEnabled: true },
    select: { id: true },
  })
  for (const member of members) {
    await sendPushToMember(member.id, {
      title: 'New BKK Community saving',
      body: `${discount.storeName}: ${discount.title}`,
      type: 'discount',
      data: { discount_id: String(discount.id) },
      dedupeKey: `new-discount:${discount.id}`,
    })
  }
}

export async function deliverDueEventReminders(): Promise<void> {
  if (!pushConfigured()) return
  const target = Date.now() + 24 * 60 * 60 * 1_000
  const rows = await prisma.attendance.findMany({
    where: {
      status: 'attending',
      event: {
        startAt: {
          gte: new Date(target - FIFTEEN_MINUTES_MS),
          lt: new Date(target + FIFTEEN_MINUTES_MS),
        },
      },
      member: { notificationsEnabled: true, eventRemindersEnabled: true },
    },
    include: { event: true },
  })

  for (const row of rows) {
    await sendPushToMember(row.memberId, {
      title: 'BKK event tomorrow',
      body: `${row.event.title} starts tomorrow at ${row.event.location}.`,
      type: 'event',
      data: { event_id: String(row.eventId) },
      dedupeKey: `event-reminder-24h:${row.eventId}`,
    })
  }
}

export function startNotificationScheduler(): NodeJS.Timeout {
  const run = () => {
    void deliverDueEventReminders().catch(error => {
      console.error('[NOTIFICATION JOB] Event reminder pass failed.', { errorName: (error as Error)?.name })
    })
  }
  run()
  const timer = setInterval(run, FIFTEEN_MINUTES_MS)
  timer.unref()
  return timer
}
