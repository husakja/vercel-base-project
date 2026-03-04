#!/usr/bin/env bash
# =============================================================================
# setup-vercel.sh
#
# Fully automates Vercel project setup:
#   1. Verifies prerequisites (Vercel CLI, login)
#   2. Links or creates the Vercel project
#   3. Creates a Vercel Postgres (Neon) database and pulls connection strings
#   4. Generates AUTH_SECRET if not already set
#   5. Pushes all variables from .env.local to Vercel (all environments)
#   6. Runs Prisma migrations against the live database
#
# Usage:
#   bash scripts/setup-vercel.sh [--db-name <name>] [--project-name <name>]
#
# Options:
#   --db-name        Name for the Vercel Postgres database  (default: project name)
#   --project-name   Vercel project name                    (default: directory name)
#   --skip-migrate   Skip running prisma migrate deploy at the end
# =============================================================================

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}${BOLD}[info]${RESET}  $*"; }
success() { echo -e "${GREEN}${BOLD}[ok]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[warn]${RESET}  $*"; }
error()   { echo -e "${RED}${BOLD}[error]${RESET} $*" >&2; }
die()     { error "$*"; exit 1; }

# ── Defaults ─────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env.local"

PROJECT_NAME="$(basename "$PROJECT_ROOT")"
DB_NAME=""
SKIP_MIGRATE=false

# ── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-name) PROJECT_NAME="$2"; shift 2 ;;
    --db-name)      DB_NAME="$2";      shift 2 ;;
    --skip-migrate) SKIP_MIGRATE=true; shift   ;;
    *) die "Unknown argument: $1" ;;
  esac
done

# Default DB name to project name if not set
DB_NAME="${DB_NAME:-$PROJECT_NAME}"

# ── Step 0: Prerequisites ─────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}=== Vercel setup ===${RESET}"
echo ""

info "Checking prerequisites..."

if ! command -v vercel &>/dev/null; then
  die "Vercel CLI not found. Install it with: npm install -g vercel"
fi
success "Vercel CLI found: $(vercel --version 2>&1 | head -1)"

if ! vercel whoami &>/dev/null; then
  die "Not logged in to Vercel. Run: vercel login"
fi
VERCEL_USER="$(vercel whoami 2>&1)"
success "Logged in as: $VERCEL_USER"

if ! command -v openssl &>/dev/null; then
  warn "openssl not found — AUTH_SECRET will not be auto-generated."
  HAS_OPENSSL=false
else
  HAS_OPENSSL=true
fi

# ── Step 1: Link / create Vercel project ──────────────────────────────────────
echo ""
info "Linking Vercel project..."

cd "$PROJECT_ROOT"

if [[ ! -f ".vercel/project.json" ]]; then
  info "No .vercel/project.json found — running 'vercel link'..."
  vercel link --yes --project "$PROJECT_NAME" 2>&1 | sed 's/^/  /'
  success "Project linked: $PROJECT_NAME"
else
  success "Project already linked ($(cat .vercel/project.json | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("projectId","unknown"))' 2>/dev/null || echo 'unknown id'))"
fi

# ── Step 2: Create Vercel Postgres database ───────────────────────────────────
echo ""
info "Setting up Vercel Postgres database '$DB_NAME'..."

# Check if database already exists by trying to list stores
EXISTING_DBS="$(vercel storage ls 2>&1 || true)"

if echo "$EXISTING_DBS" | grep -q "$DB_NAME"; then
  warn "A storage resource named '$DB_NAME' already exists — skipping creation."
else
  info "Creating Postgres database '$DB_NAME'..."
  # vercel postgres create <name> --yes skips interactive prompts
  if vercel postgres create "$DB_NAME" --yes 2>&1 | sed 's/^/  /'; then
    success "Postgres database '$DB_NAME' created."
  else
    warn "Could not create database automatically (may already exist or need a paid plan)."
    warn "Create it manually in the Vercel dashboard, then re-run this script."
    warn "Continuing with remaining env var setup..."
  fi
fi

# ── Step 3: Pull env vars from Vercel (includes DATABASE_URL from Postgres) ───
echo ""
info "Pulling environment variables from Vercel into .env.local..."

vercel env pull "$ENV_FILE" --yes 2>&1 | sed 's/^/  /'
success "Environment variables written to .env.local"

# ── Step 4: Generate AUTH_SECRET if missing ───────────────────────────────────
echo ""
info "Checking AUTH_SECRET..."

if grep -q "^AUTH_SECRET=" "$ENV_FILE" && ! grep -q "^AUTH_SECRET=$" "$ENV_FILE"; then
  success "AUTH_SECRET already set — skipping."
else
  if [[ "$HAS_OPENSSL" == true ]]; then
    AUTH_SECRET="$(openssl rand -base64 32)"
    info "Generated new AUTH_SECRET."

    # Write to .env.local
    if grep -q "^AUTH_SECRET=" "$ENV_FILE" 2>/dev/null; then
      # Replace existing empty value
      sed -i "s|^AUTH_SECRET=.*|AUTH_SECRET=$AUTH_SECRET|" "$ENV_FILE"
    else
      echo "AUTH_SECRET=$AUTH_SECRET" >> "$ENV_FILE"
    fi

    # Push to Vercel for all environments
    info "Pushing AUTH_SECRET to Vercel (production, preview, development)..."
    echo "$AUTH_SECRET" | vercel env add AUTH_SECRET production  --yes 2>&1 | sed 's/^/  /' || true
    echo "$AUTH_SECRET" | vercel env add AUTH_SECRET preview     --yes 2>&1 | sed 's/^/  /' || true
    echo "$AUTH_SECRET" | vercel env add AUTH_SECRET development --yes 2>&1 | sed 's/^/  /' || true
    success "AUTH_SECRET pushed to Vercel."
  else
    warn "Cannot auto-generate AUTH_SECRET (openssl missing)."
    warn "Generate one manually:  openssl rand -base64 32"
    warn "Then add it:            vercel env add AUTH_SECRET production"
  fi
fi

# ── Step 5: Push remaining .env.local vars to Vercel ─────────────────────────
echo ""
info "Pushing all .env.local variables to Vercel..."

PUSHED=0
SKIPPED=0

while IFS= read -r line || [[ -n "$line" ]]; do
  # Skip blank lines and comments
  [[ -z "$line" || "$line" == \#* ]] && continue

  KEY="${line%%=*}"
  VALUE="${line#*=}"

  # Skip empty values
  if [[ -z "$VALUE" ]]; then
    warn "  Skipping $KEY (empty value)"
    (( SKIPPED++ )) || true
    continue
  fi

  # Skip keys that Vercel Postgres already injected (they're already there)
  if [[ "$KEY" == "POSTGRES_"* || "$KEY" == "DATABASE_URL"* ]]; then
    success "  $KEY — already managed by Vercel Postgres, skipping push."
    (( SKIPPED++ )) || true
    continue
  fi

  info "  Pushing $KEY..."
  # Use printf to avoid issues with special characters in values
  printf '%s' "$VALUE" | vercel env add "$KEY" production  --yes 2>&1 | grep -v "^$" | sed 's/^/    /' || true
  printf '%s' "$VALUE" | vercel env add "$KEY" preview     --yes 2>&1 | grep -v "^$" | sed 's/^/    /' || true
  printf '%s' "$VALUE" | vercel env add "$KEY" development --yes 2>&1 | grep -v "^$" | sed 's/^/    /' || true
  (( PUSHED++ )) || true

done < "$ENV_FILE"

success "Done: $PUSHED variable(s) pushed, $SKIPPED skipped."

# ── Step 6: Run Prisma migrations ─────────────────────────────────────────────
echo ""
if [[ "$SKIP_MIGRATE" == true ]]; then
  warn "Skipping Prisma migrations (--skip-migrate was set)."
else
  info "Running Prisma migrations against the database..."

  # Source .env.local so Prisma can read DATABASE_URL
  set -o allexport
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +o allexport

  if npx prisma migrate deploy 2>&1 | sed 's/^/  /'; then
    success "Prisma migrations applied."
  else
    warn "Prisma migrate deploy failed."
    warn "You may need to run it manually once DATABASE_URL is confirmed:"
    warn "  npx prisma migrate deploy"
  fi
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}=== Setup complete ===${RESET}"
echo ""
echo -e "  ${BOLD}Next steps:${RESET}"
echo -e "  1. Deploy:         ${CYAN}vercel --prod${RESET}"
echo -e "  2. Seed the DB:    ${CYAN}npm run db:seed${RESET}"
echo -e "  3. Open Studio:    ${CYAN}npm run db:studio${RESET}"
echo ""
