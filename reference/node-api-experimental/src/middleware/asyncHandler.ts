import { NextFunction, Request, RequestHandler, Response } from 'express'

type AsyncRequestHandler<TRequest extends Request = Request> = (
  req: TRequest,
  res: Response,
  next: NextFunction,
) => Promise<unknown>

/**
 * Express 4 does not forward rejected async route promises to error middleware.
 * This small wrapper keeps every rejected promise on the normal error path.
 */
export function asyncHandler<TRequest extends Request>(
  handler: AsyncRequestHandler<TRequest>,
): RequestHandler {
  return (req, res, next) => {
    void handler(req as TRequest, res, next).catch(next)
  }
}
