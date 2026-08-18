import { Router, Request, Response } from 'express'
import prisma from '../db'
import { asyncHandler } from '../middleware/asyncHandler'

export const servicesRouter = Router()

const serviceDto = (s: { id: number; type: string; name: string; address: string; phone: string; directions: string | null; openingHours: string | null }) => ({
  id: s.id,
  type: s.type,
  name: s.name,
  address: s.address,
  phone: s.phone,
  directions: s.directions,
  opening_hours: s.openingHours,
})

// GET /local-services
servicesRouter.get('/', asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const type = typeof req.query.type === 'string' ? req.query.type : undefined
  const services = await prisma.localService.findMany({
    where: type ? { type } : undefined,
    orderBy: [{ type: 'asc' }, { name: 'asc' }],
  })
  res.json({ data: services.map(serviceDto) })
}))
