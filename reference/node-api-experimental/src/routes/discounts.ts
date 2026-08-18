import { Router, Request, Response } from 'express'
import prisma from '../db'
import { asyncHandler } from '../middleware/asyncHandler'

export const discountsRouter = Router()

const discountDto = (d: { id: number; storeName: string; title: string; details: string; eligibility: string; claimInstructions: string; category: string; validFrom: Date | null; validUntil: Date | null }) => ({
  id: d.id,
  store_name: d.storeName,
  title: d.title,
  details: d.details,
  eligibility: d.eligibility,
  claim_instructions: d.claimInstructions,
  category: d.category,
  valid_from: d.validFrom?.toISOString() ?? null,
  valid_until: d.validUntil?.toISOString() ?? null,
})

// GET /discounts
discountsRouter.get('/', asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const category = typeof req.query.category === 'string' ? req.query.category : undefined
  const discounts = await prisma.discount.findMany({
    where: category ? { category } : undefined,
    orderBy: { storeName: 'asc' },
  })
  res.json({ data: discounts.map(discountDto) })
}))

// GET /discounts/:id
discountsRouter.get('/:id', asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const idStr = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id
  const id = parseInt(idStr, 10)
  const discount = await prisma.discount.findUnique({ where: { id } })
  if (!discount) { res.status(404).json({ error: { message: 'Discount not found.' } }); return }
  res.json({ data: discountDto(discount) })
}))
