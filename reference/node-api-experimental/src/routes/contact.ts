import { Router, Request, Response } from 'express'
import prisma from '../db'
import { validate, ContactSchema } from '../middleware/validate'
import { contactLimiter } from '../middleware/rateLimit'
import { asyncHandler } from '../middleware/asyncHandler'

export const contactRouter = Router()

// POST /contact
contactRouter.post('/', contactLimiter, validate(ContactSchema), asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const { name, email, message } = req.body
  if (!name || !email || !message) {
    res.status(422).json({ error: { message: 'Name, email and message are required.' } })
    return
  }
  const record = await prisma.contactMessage.create({ data: { name, email, message } })
  res.status(201).json({ data: { id: record.id, message: 'Thank you. Your message has been received.' } })
}))
