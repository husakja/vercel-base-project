import { PrismaClient } from '@prisma/client'
import { PrismaNeon } from '@prisma/adapter-neon'

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

function createPrismaClient() {
  const log = process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error']

  const shouldUseNeonAdapter =
    process.env.DATABASE_URL?.includes('neon.tech') ||
    process.env.DATABASE_URL?.includes('neon.database.azure.com')

  if (shouldUseNeonAdapter) {
    // PrismaNeon accepts a PoolConfig directly (connection string or config object)
    const adapter = new PrismaNeon({
      connectionString: process.env.DATABASE_URL,
    })

    return new PrismaClient({
      adapter,
      log,
    })
  }

  return new PrismaClient({ log })
}

// Reuse the same PrismaClient instance across hot reloads in development
// to avoid exhausting database connections.
export const db = globalForPrisma.prisma ?? createPrismaClient()

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = db
