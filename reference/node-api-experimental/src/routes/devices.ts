import { Router, Response } from 'express'
import prisma from '../db'
import { requireAuth, AuthRequest } from '../middleware/auth'
import { validate, FcmTokenSchema, TestPushSchema } from '../middleware/validate'
import { PushNotConfiguredError, sendPushToMember } from '../services/push'
import { asyncHandler } from '../middleware/asyncHandler'

export const devicesRouter = Router()
devicesRouter.use(requireAuth)

devicesRouter.put('/fcm-token', validate(FcmTokenSchema), asyncHandler(async (req: AuthRequest, res: Response): Promise<void> => {
  const { fcm_token, notifications_enabled, platform } = req.body
  await prisma.deviceToken.upsert({
    where: { fcmToken: fcm_token },
    update: {
      memberId: req.memberId!,
      notificationsEnabled: notifications_enabled,
      platform,
      lastSeenAt: new Date(),
    },
    create: {
      memberId: req.memberId!,
      fcmToken: fcm_token,
      notificationsEnabled: notifications_enabled,
      platform,
    },
  })
  res.json({ data: { registered: true } })
}))

// This endpoint performs a real provider call; it never reports simulated delivery.
devicesRouter.post('/test-push', validate(TestPushSchema), asyncHandler(async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const result = await sendPushToMember(req.memberId!, {
      title: req.body.title ?? 'BKK Community notification test',
      body: req.body.body ?? 'Notifications are connected to this device.',
      type: 'test',
      data: req.body.event_id ? { event_id: String(req.body.event_id) } : {},
    })
    res.json({ data: result })
  } catch (error) {
    if (error instanceof PushNotConfiguredError) {
      res.status(503).json({ error: { message: 'Push notifications are not configured on this server.' } })
      return
    }
    throw error
  }
}))
