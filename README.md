# vercel-boilerplate

Minimal Next.js 15 + Prisma + NextAuth starter with local Docker services.

## Prerequisites

- Node.js 18+
- Docker + Docker Compose

## Quick start

```bash
npm install
cp .env.docker.example .env.local
npm run docker:up
npm run db:push
npm run db:seed
npm run dev
```

## Local URLs

- App: http://localhost:3000
- Mailhog UI: http://localhost:8025
- Prisma Studio: http://localhost:5555

## Seeded users

- Admin: `admin@example.com` / `admin123`
- User: `user@example.com` / `user123`

## Useful scripts

- `npm run dev` - Start Next.js dev server
- `npm run lint` - Run lint checks
- `npm run build` - Build for production
- `npm run db:generate` - Generate Prisma client
- `npm run db:migrate` - Run Prisma migrations
- `npm run db:push` - Push schema to database
- `npm run db:seed` - Seed database
- `npm run db:studio` - Open Prisma Studio
- `npm run docker:up` - Start local Docker services
- `npm run docker:down` - Stop local Docker services
- `npm run docker:logs` - Tail Docker logs
- `npm run setup` - Run Vercel setup script
