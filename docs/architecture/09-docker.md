## Stage 8 — Docker

### Goal
Containerize the CineSangeet application using Docker best practices.

### What Was Done
- Created a **multi-stage Dockerfile** with builder and runtime stages
- Implemented **non-root user** for container security
- Wrote `.dockerignore` to exclude unnecessary files from the build context
- Built the image as `cinesangeet:v3`
- Ran the container and verified application functionality
- Performed security scan with **Trivy**

### Dockerfile Structure
```dockerfile
# Stage 1: Builder — installs dependencies
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Runtime — minimal image with app
FROM node:20-alpine
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
```
