# ================================
# 1️⃣ Base
# ================================
FROM node:20-alpine AS base

RUN apk add --no-cache libc6-compat
WORKDIR /app

# Enable pnpm via corepack
RUN corepack enable

# ================================
# 2️⃣ Dependencies
# ================================
FROM base AS deps

COPY package.json pnpm-lock.yaml ./

RUN pnpm install --frozen-lockfile

# ================================
# 3️⃣ Build
# ================================
FROM base AS builder

ENV NEXT_TELEMETRY_DISABLED=1

COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN pnpm build

# ================================
# 4️⃣ Production runner
# ================================
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Create non-root user (security)
RUN addgroup -g 1001 -S nodejs \
  && adduser -S nextjs -u 1001

# Copy minimal standalone output
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# Fix permissions
RUN chown -R nextjs:nodejs /app

USER nextjs

EXPOSE 3000

CMD ["node", "server.js"]
