import crypto from 'crypto'
import { Prisma } from '@prisma/client'
import { config } from '../config'
import prisma from '../db'

export class PushNotConfiguredError extends Error {
  constructor(message = 'Firebase push delivery is not configured.') {
    super(message)
    this.name = 'PushNotConfiguredError'
  }
}

interface FirebaseServiceAccount {
  project_id: string
  client_email: string
  private_key: string
}

interface PushMessage {
  title: string
  body: string
  type: string
  data?: Record<string, string>
  /** Stable logical notification key; a per-device suffix is added automatically. */
  dedupeKey?: string
}

interface AccessToken {
  value: string
  expiresAt: number
}

let cachedAccessToken: AccessToken | undefined

export function pushConfigured(): boolean {
  return Boolean(config.FIREBASE_SERVICE_ACCOUNT_JSON)
}

function serviceAccount(): FirebaseServiceAccount {
  if (!config.FIREBASE_SERVICE_ACCOUNT_JSON) throw new PushNotConfiguredError()

  let parsed: Partial<FirebaseServiceAccount>
  try {
    parsed = JSON.parse(config.FIREBASE_SERVICE_ACCOUNT_JSON) as Partial<FirebaseServiceAccount>
  } catch {
    throw new PushNotConfiguredError('FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON.')
  }

  if (!parsed.project_id || !parsed.client_email || !parsed.private_key) {
    throw new PushNotConfiguredError('Firebase service-account fields are incomplete.')
  }
  return parsed as FirebaseServiceAccount
}

function base64UrlJson(value: object): string {
  return Buffer.from(JSON.stringify(value)).toString('base64url')
}

async function firebaseAccessToken(account: FirebaseServiceAccount): Promise<string> {
  if (cachedAccessToken && cachedAccessToken.expiresAt > Date.now() + 60_000) {
    return cachedAccessToken.value
  }

  const issuedAt = Math.floor(Date.now() / 1_000)
  const unsignedJwt = [
    base64UrlJson({ alg: 'RS256', typ: 'JWT' }),
    base64UrlJson({
      iss: account.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: issuedAt,
      exp: issuedAt + 3_600,
    }),
  ].join('.')
  const signature = crypto.sign('RSA-SHA256', Buffer.from(unsignedJwt), account.private_key).toString('base64url')

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: `${unsignedJwt}.${signature}`,
    }),
  })
  const payload = await response.json() as { access_token?: string; expires_in?: number }
  if (!response.ok || !payload.access_token) throw new Error('Firebase authentication failed.')

  cachedAccessToken = {
    value: payload.access_token,
    expiresAt: Date.now() + (payload.expires_in ?? 3_600) * 1_000,
  }
  return cachedAccessToken.value
}

export async function sendPushToMember(memberId: number, message: PushMessage) {
  const devices = await prisma.deviceToken.findMany({
    where: { memberId, notificationsEnabled: true },
    select: { id: true, fcmToken: true },
  })
  if (!devices.length) return { attempted: 0, delivered: 0, failed: 0 }

  const account = serviceAccount()
  const accessToken = await firebaseAccessToken(account)
  const responses = await Promise.all(devices.map(async device => {
    const dedupeKey = message.dedupeKey ? `${message.dedupeKey}:device:${device.id}`.slice(0, 191) : null
    let logId: number | undefined
    if (dedupeKey) {
      try {
        const log = await prisma.notificationLog.create({
          data: {
            memberId,
            deviceTokenId: device.id,
            notificationType: message.type,
            dedupeKey,
            status: 'sending',
          },
        })
        logId = log.id
      } catch (error) {
        if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
          return { delivered: false, skipped: true }
        }
        throw error
      }
    }

    try {
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${encodeURIComponent(account.project_id)}/messages:send`,
        {
          method: 'POST',
          headers: {
            authorization: `Bearer ${accessToken}`,
            'content-type': 'application/json',
          },
          body: JSON.stringify({
            message: {
              token: device.fcmToken,
              notification: { title: message.title, body: message.body },
              data: { type: message.type, ...message.data },
              android: { priority: 'high' },
              apns: { payload: { aps: { sound: 'default' } } },
            },
          }),
        },
      )
      const payload = await response.json().catch(() => ({})) as {
        name?: string
        error?: { status?: string }
      }
      const errorCode = payload.error?.status?.slice(0, 100) ?? null
      const logData = {
        providerMessageId: payload.name?.slice(0, 255) ?? null,
        status: response.ok ? 'accepted' : 'failed',
        errorCode,
      }
      if (logId) {
        await prisma.notificationLog.update({ where: { id: logId }, data: logData })
      } else {
        await prisma.notificationLog.create({
          data: { memberId, deviceTokenId: device.id, notificationType: message.type, ...logData },
        })
      }
      if (response.status === 404 || errorCode === 'UNREGISTERED') {
        await prisma.deviceToken.delete({ where: { id: device.id } })
      }
      return { delivered: response.ok, skipped: false }
    } catch (error) {
      if (logId) {
        await prisma.notificationLog.update({
          where: { id: logId },
          data: { status: 'failed', errorCode: 'DELIVERY_EXCEPTION' },
        }).catch(() => undefined)
      }
      return { delivered: false, skipped: false }
    }
  }))

  const delivered = responses.filter(result => result.delivered).length
  const skipped = responses.filter(result => result.skipped).length
  return { attempted: devices.length - skipped, delivered, failed: devices.length - skipped - delivered, skipped }
}
