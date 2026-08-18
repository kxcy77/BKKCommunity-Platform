export type EventSafetyFields = {
  title: string
  description: string
  location: string
  category: string
}

export const isDemonstrationEvent = (event: EventSafetyFields): boolean => {
  const category = event.category.trim().toLowerCase()
  const title = event.title.toLowerCase()
  const description = event.description.toLowerCase()
  const location = event.location.toLowerCase()

  return category === 'demonstration'
    || title.includes('not a real event')
    || description.includes('test content only')
    || location.includes('do not travel')
}
