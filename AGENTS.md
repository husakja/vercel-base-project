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

Recommended MCP servers for this stack:

- `next-devtools-mcp` (Next.js)
  - transport: `stdio`
  - startup command: `npx -y next-devtools-mcp@latest`
  - scope: Next.js docs lookup, upgrade/codemod workflows, browser automation, and runtime diagnostics from a running Next.js dev server (`/_next/mcp`)
  - required credentials: none

- `@mistertk/vercel-mcp` (Vercel platform)
  - transport: `stdio`
  - startup command: `npx -y @mistertk/vercel-mcp`
  - scope: Vercel projects, deployments, domains, DNS, environment variables, teams, webhooks, and related platform operations
  - required credentials: `VERCEL_API_KEY` (required), plus optional team/project IDs depending on the operation

- `@iflow-mcp/coppinaphil-tailwind-mcp-server` (Tailwind CSS)
  - transport: `stdio`
  - startup command: `npx -y @iflow-mcp/coppinaphil-tailwind-mcp-server`
  - scope: Tailwind component generation, class validation/optimization, theme/config generation, responsive pattern guidance
  - required credentials: none

- `@hypnosis/docker-mcp-server` (Docker and Docker Compose)
  - transport: `stdio`
  - startup command: `npx -y @hypnosis/docker-mcp-server`
  - scope: container lifecycle, logs, compose up/down, compose config discovery, health checks, and Docker resource inspection
  - required credentials: local Docker socket access; optional SSH profile credentials for remote Docker hosts

- `@modelcontextprotocol/server-postgres` (PostgreSQL)
  - transport: `stdio`
  - startup command: `npx -y @modelcontextprotocol/server-postgres postgresql://USER:PASSWORD@HOST:5432/DB_NAME`
  - scope: read-only SQL queries and table/schema introspection resources for PostgreSQL databases
  - required credentials: PostgreSQL connection string (local Docker Postgres or hosted Neon/Postgres)

Notes:
- Prefer read-only database MCP usage in shared/production environments.
- This project uses local Postgres via `docker-compose.yml` and hosted Neon-compatible Postgres in Vercel environments.

Project config:
- `mcp.config.example.json` contains a ready-to-adapt MCP client config for this stack.
- Client-specific templates are also provided:
  - `mcp.codex.example.toml` for Codex (`~/.codex/config.toml`)
  - `mcp.claude.example.json` for Claude Code project scope (`.mcp.json`)
  - `mcp.opencode.example.json` for OpenCode (`opencode.json`)
- Ready-to-use project-scoped configs are included:
  - `.codex/config.toml` (Codex)
  - `.mcp.json` (Claude Code)
  - `opencode.json` (OpenCode)
- Copy required keys from `.env.example` (or `.env.docker.example`) into your local environment before enabling all servers.
- Required for full setup: `VERCEL_API_KEY` and `MCP_POSTGRES_URL` (you can reuse `DATABASE_URL` for local/dev).

Quick setup:
1. Populate MCP env vars in `.env.local` from `.env.example`.
2. Use the ready project config for your client (`.mcp.json`, `opencode.json`, or `.codex/config.toml`), or copy a client-specific template if you prefer.
3. Start services as needed (`npm run dev` for Next.js runtime MCP, `npm run docker:up` for local Docker/Postgres).

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
