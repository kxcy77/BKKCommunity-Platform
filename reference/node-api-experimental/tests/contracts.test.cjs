const test = require('node:test')
const assert = require('node:assert/strict')
const { spawnSync } = require('node:child_process')
const path = require('node:path')

const {
  AdminEventSchema,
  AdminRoleSchema,
  AttendanceSchema,
  ContactSchema,
  ResetPasswordSchema,
} = require('../dist/middleware/validate.js')
const { isDemonstrationEvent } = require('../dist/domain/eventSafety.js')

test('demonstration events are detected independently of their database ID', () => {
  assert.equal(isDemonstrationEvent({
    title: 'BKK App Demonstration Event - Not a Real Event',
    description: 'TEST CONTENT ONLY',
    location: 'Demonstration only - do not travel',
    category: 'Demonstration',
  }), true)
  assert.equal(isDemonstrationEvent({
    title: 'Community lunch',
    description: 'Meet neighbours for lunch.',
    location: 'BKK Community Hall',
    category: 'Social',
  }), false)
})

test('password reset is bound to a normalized email and exactly six digits', () => {
  const valid = ResetPasswordSchema.safeParse({
    email: ' Member@Example.com ',
    token: '012345',
    password: 'newPassword1',
  })
  assert.equal(valid.success, true)
  assert.equal(valid.data.email, 'member@example.com')
  assert.equal(ResetPasswordSchema.safeParse({ token: '012345', password: 'newPassword1' }).success, false)
  assert.equal(ResetPasswordSchema.safeParse({ email: 'member@example.com', token: '12345', password: 'newPassword1' }).success, false)
})

test('attendance status and administrator role payloads are strict', () => {
  assert.equal(AttendanceSchema.safeParse({ status: 'attending' }).success, true)
  assert.equal(AttendanceSchema.safeParse({ status: 'cancelled' }).success, true)
  assert.equal(AttendanceSchema.safeParse({ status: 'not_attending' }).success, false)
  assert.equal(AdminRoleSchema.safeParse({ isAdmin: false }).success, true)
  assert.equal(AdminRoleSchema.safeParse({ isAdmin: 'false' }).success, false)
})

test('admin events require offset timestamps and chronological order', () => {
  const event = {
    title: 'Exercise',
    description: 'Gentle community exercise class.',
    startAt: '2026-08-14T09:00:00+02:00',
    endAt: '2026-08-14T10:00:00+02:00',
    location: 'Community hall',
    directions: null,
    category: 'Exercise',
    colourHex: '#1F4E79',
  }
  assert.equal(AdminEventSchema.safeParse(event).success, true)
  assert.equal(AdminEventSchema.safeParse({ ...event, endAt: event.startAt }).success, false)
  assert.equal(AdminEventSchema.safeParse({ ...event, startAt: '2026-08-14T09:00' }).success, false)
})

test('contact validation rejects spam-sized or meaningless messages', () => {
  assert.equal(ContactSchema.safeParse({ name: 'Nomsa', email: 'nomsa@example.com', message: 'Please send details about the Friday event.' }).success, true)
  assert.equal(ContactSchema.safeParse({ name: 'Nomsa', email: 'nomsa@example.com', message: 'Hello' }).success, false)
  assert.equal(ContactSchema.safeParse({ name: 'Nomsa', email: 'nomsa@example.com', message: 'x'.repeat(3001) }).success, false)
})

test('server configuration fails closed when secrets are missing', () => {
  const configPath = path.resolve(__dirname, '../dist/config.js')
  const result = spawnSync(process.execPath, ['-e', `require(${JSON.stringify(configPath)})`], {
    env: { PATH: process.env.PATH, NODE_ENV: 'production', DATABASE_URL: 'mysql://user:pass@db:3306/bkk' },
    encoding: 'utf8',
  })
  assert.notEqual(result.status, 0)
  assert.match(result.stderr, /Invalid server configuration/)
})
