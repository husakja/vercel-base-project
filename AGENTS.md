# AI Agent Instructions

This document defines how AI coding agents should operate in this repository.

## Project Overview

- Stack: Next.js 15 (App Router), React 18, TypeScript, Prisma, NextAuth v5
- Database: PostgreSQL (Neon in hosted environments, local Postgres via Docker)
- Styling: Tailwind CSS + PostCSS
- Auth: NextAuth with Prisma adapter and credentials/OAuth providers
- Runtime: Node.js

## Project Structure

Top-level layout:

- `app/` - Next.js App Router pages and API routes
  - `app/page.tsx` - homepage
  - `app/layout.tsx` - root layout and global wrappers
  - `app/api/auth/[...nextauth]/route.ts` - NextAuth handlers
  - `app/api/users/route.ts` - protected users endpoint
- `lib/` - shared server code
  - `lib/auth.ts` - NextAuth configuration
  - `lib/db.ts` - Prisma client creation and adapter selection
- `prisma/` - database schema and seed logic
  - `prisma/schema.prisma` - Prisma schema
  - `prisma/seed.ts` - seed script
- `types/` - TypeScript declaration merging
  - `types/next-auth.d.ts` - NextAuth type extensions
- `scripts/` - utility shell scripts
  - `scripts/setup-vercel.sh` - Vercel + Neon setup flow
- Infra/config
  - `docker-compose.yml` - local dev services (postgres, redis, mailhog, prisma-studio)
  - `next.config.ts`, `tsconfig.json`, `tailwind.config.ts`, `postcss.config.mjs`
  - `.eslintrc.json`, `.prettierrc`, `.env.example`, `.env.docker.example`

## Local Services

Docker Compose services for local development:

- Postgres: `localhost:5432`
- Redis: `localhost:6379`
- Mailhog SMTP: `localhost:1025`
- Mailhog UI: `http://localhost:8025`
- Prisma Studio: `http://localhost:5555`

Use:

- `npm run docker:up`
- `npm run docker:down`
- `npm run docker:logs`

## MCP Servers

No MCP server configuration is currently present in this repository.

If MCP is introduced later, document it in this section with:

- server name
- transport (stdio/http)
- startup command
- scope (what tools/resources it exposes)
- required credentials

## LSP and Tooling Guidance

This repo does not explicitly pin LSP server config files; use standard language servers below.

- TypeScript/JavaScript: `typescript-language-server` (or editor tsserver integration)
- ESLint: `vscode-eslint-language-server` / ESLint extension
- Tailwind CSS: `tailwindcss-language-server`
- Prisma: Prisma language server/editor extension
- JSON: `vscode-json-language-server`
- Shell scripts: `bash-language-server`

Complementary CLI tools used by agents:

- `npm run lint` for lint checks
- `npm run build` for production build validation
- Prisma CLI via scripts: `npm run db:migrate`, `npm run db:push`, `npm run db:seed`

## Agent Operating Rules

1. Read before writing
- Inspect related files before changing implementation.
- Follow existing code style (2-space indent, single quotes, no semicolons).

2. Keep changes minimal and scoped
- Do not refactor unrelated code.
- Avoid broad formatting churn.

3. Preserve environment compatibility
- Hosted DB may use Neon adapter; local DB uses standard Postgres.
- Do not hardcode secrets; use env vars only.

4. Validate after changes
- Run `npm run lint` at minimum.
- For data model or auth changes, also run relevant Prisma commands.

5. API and auth safety
- Treat `app/api/*` as server-side code.
- Keep protected endpoints authorization checks intact.

6. Infra changes
- Keep Docker defaults local-development focused.
- Prefer additive changes in `docker-compose.yml` and env examples.

## Agent Task Checklist

Before opening a PR or finishing a task:

- Confirm env keys are documented in `.env.example` or `.env.docker.example`
- Confirm lint passes
- Confirm changed scripts/config are runnable
- Summarize what changed, why, and any manual follow-up
