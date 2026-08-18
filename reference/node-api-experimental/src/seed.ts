import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

async function main() {
  if (process.env.ALLOW_DEMO_SEED !== 'true') {
    throw new Error('Demo seed refused. Set ALLOW_DEMO_SEED=true only for a disposable development database.')
  }
  console.log('Seeding clearly labelled demonstration content into a disposable database...')

  // Clear existing data
  await prisma.attendance.deleteMany()
  await prisma.deviceToken.deleteMany()
  await prisma.passwordReset.deleteMany()
  await prisma.contactMessage.deleteMany()
  await prisma.event.deleteMany()
  await prisma.discount.deleteMany()
  await prisma.localService.deleteMany()

  // Helper: date relative to today (Johannesburg time)
  const base = new Date()
  base.setHours(0, 0, 0, 0)
  const d = (dayOffset: number, hour: number, minute: number) => {
    const dt = new Date(base)
    dt.setDate(dt.getDate() + dayOffset)
    dt.setHours(hour, minute, 0, 0)
    return dt
  }

  // Events
  await prisma.event.createMany({
    data: [
      {
        title: 'Morning Exercise Class',
        description: 'A gentle, low-impact exercise session suitable for all fitness levels and mobility. Led by our qualified biokineticist.',
        startAt: d(0, 9, 0),
        endAt: d(0, 9, 45),
        location: 'Community Hall — Block B',
        directions: 'Use the Block B entrance on the left side of the building. Chairs and mats provided.',
        category: 'Exercise',
        colourHex: '#315C24',
      },
      {
        title: 'Social Lunch Gathering',
        description: 'Share a light lunch and connect with other BKK community members. Tea and coffee served. Bring a dish to share if you like.',
        startAt: d(2, 12, 0),
        endAt: d(2, 13, 30),
        location: 'BKK Community Hall — Main Hall',
        directions: 'Main entrance on Main Road. Parking available at the back.',
        category: 'Social',
        colourHex: '#2E75B6',
      },
      {
        title: 'Health Talk: Managing Diabetes',
        description: 'A practical information session on managing Type 2 diabetes through diet, exercise and medication. Time allowed for questions.',
        startAt: d(4, 14, 0),
        endAt: d(4, 15, 30),
        location: 'BKK Clinic — Room 2',
        directions: 'Enter through the clinic reception. Room 2 is down the corridor on the right.',
        category: 'Health',
        colourHex: '#B00020',
      },
      {
        title: 'Bingo Afternoon',
        description: 'Enjoy a fun afternoon of bingo with prizes! Cards provided. Light refreshments served.',
        startAt: d(5, 14, 0),
        endAt: d(5, 16, 0),
        location: 'Community Hall — Block A',
        directions: 'Main Road entrance. Hall is straight ahead from reception.',
        category: 'Social',
        colourHex: '#7B3F9E',
      },
      {
        title: 'Memory & Brain Health Workshop',
        description: 'Learn practical techniques to keep your mind sharp, including memory exercises, lifestyle tips and early warning signs to watch for.',
        startAt: d(7, 10, 0),
        endAt: d(7, 11, 30),
        location: 'BKK Clinic — Conference Room',
        directions: 'Follow signs from the main reception.',
        category: 'Health',
        colourHex: '#B00020',
      },
      {
        title: 'Walking Group — Morning Stroll',
        description: 'A relaxed guided walk around the neighbourhood. Comfortable shoes recommended. Suitable for all fitness levels.',
        startAt: d(9, 7, 30),
        endAt: d(9, 9, 0),
        location: 'BKK Community Hall Parking Lot',
        directions: 'Meet at the main entrance. The group departs promptly at 07:30.',
        category: 'Exercise',
        colourHex: '#315C24',
      },
    ],
  })

  // Discounts
  await prisma.discount.createMany({
    data: [
      {
        storeName: 'Clicks',
        title: '10% off selected prescriptions',
        details: 'Senior members aged 60 and over receive a 10% discount on selected prescription and over-the-counter medication every day.',
        eligibility: 'Customers aged 60 or older with a valid South African ID.',
        claimInstructions: 'Present your ID at the pharmacy counter before payment is processed.',
        category: 'Pharmacy',
        validFrom: null,
        validUntil: null,
      },
      {
        storeName: 'Checkers',
        title: 'Tuesday Senior Savings — 5% off',
        details: 'Every Tuesday, senior shoppers receive a 5% discount on qualifying grocery purchases. Exclusions apply to tobacco, alcohol and gift cards.',
        eligibility: 'Customers aged 60 or older.',
        claimInstructions: 'Present your South African ID before the cashier processes payment.',
        category: 'Grocery',
        validFrom: null,
        validUntil: null,
      },
      {
        storeName: 'Wimpy',
        title: 'Senior Breakfast Special before 10:00',
        details: 'Enjoy a reduced-price breakfast (eggs, toast, and coffee or tea) when you arrive before 10:00 on weekdays.',
        eligibility: 'Customers aged 60 or older.',
        claimInstructions: 'Ask your server for the Senior Breakfast Menu when you are seated.',
        category: 'Restaurant',
        validFrom: null,
        validUntil: null,
      },
      {
        storeName: 'Dischem',
        title: '15% Senior Discount on Tuesdays',
        details: 'Senior members receive a 15% discount storewide on Tuesdays. Applicable to most health, beauty and pharmacy products.',
        eligibility: 'Customers aged 60 or older with a Benefit Card and valid ID.',
        claimInstructions: 'Swipe your Dischem Benefit Card and present your ID before payment.',
        category: 'Pharmacy',
        validFrom: null,
        validUntil: null,
      },
      {
        storeName: 'Pick n Pay',
        title: 'Smart Shopper Senior Points Boost',
        details: 'Earn double Smart Shopper points on Wednesdays on selected grocery categories.',
        eligibility: 'Customers aged 60+ with a Smart Shopper card.',
        claimInstructions: 'Swipe your Smart Shopper card at checkout every Wednesday.',
        category: 'Grocery',
        validFrom: null,
        validUntil: null,
      },
    ],
  })

  // Local Services
  await prisma.localService.createMany({
    data: [
      {
        type: 'clinic',
        name: 'BKK Community Clinic',
        address: '12 Main Road, BKK',
        phone: '011 555 0101',
        directions: 'Directly opposite the BKK Community Hall. Ground floor, clearly signposted.',
        openingHours: 'Monday – Friday: 08:00 – 16:00',
      },
      {
        type: 'pharmacy',
        name: 'Community Pharmacy',
        address: '18 Main Road, BKK',
        phone: '011 555 0102',
        directions: 'Next to the Pick n Pay grocery store. Ramp access on the right side.',
        openingHours: 'Monday – Saturday: 08:00 – 18:00',
      },
      {
        type: 'support',
        name: 'BKK Community Support Desk',
        address: 'BKK Community Hall, Main Road',
        phone: '072 888 5030',
        directions: 'Reception desk just inside the main entrance of the Community Hall.',
        openingHours: 'Weekdays: 09:00 – 15:00',
      },
      {
        type: 'transport',
        name: 'BKK Community Shuttle Service',
        address: 'BKK Community Hall Parking Lot',
        phone: '072 888 5031',
        directions: 'Pickup point at the main parking lot entrance. Advance booking required.',
        openingHours: 'Monday, Wednesday, Friday: 09:00 – 13:00',
      },
      {
        type: 'social-work',
        name: 'Social Worker — Ms. Dlamini',
        address: 'BKK Clinic, Room 5',
        phone: '011 555 0105',
        directions: 'Room 5 is at the end of the main corridor in the BKK Clinic.',
        openingHours: 'Tuesday & Thursday: 09:00 – 14:00 (by appointment)',
      },
    ],
  })

  console.log('Demo seed complete — replace every record with approved BKK content before release.')
}

main()
  .catch(e => { console.error(e); process.exit(1) })
  .finally(() => prisma.$disconnect())
