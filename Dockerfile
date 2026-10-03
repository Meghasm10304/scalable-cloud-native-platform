# Stage 1 - Build: install production dependencies only
FROM node:24-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci --omit=dev

# Stage 2 - Runtime: minimal image with only what is needed to run
FROM node:24-alpine

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy package.json so dependency tooling/scanners can read declared deps
COPY package.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY server.js .
COPY public/ ./public/

USER appuser

EXPOSE 3000

CMD ["node", "server.js"]
