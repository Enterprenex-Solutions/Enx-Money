# Multi-stage Production Dockerfile for ENX Money Backend
# Build Stage
FROM node:20-alpine AS builder

WORKDIR /app

# Install build dependencies
COPY package*.json ./
RUN npm ci --only=production

# Production Runner Stage
FROM node:20-alpine AS runner

WORKDIR /app

# Set production environment variables
ENV NODE_ENV=production \
    PORT=5000 \
    APP_NAME=enx-money-backend

# Install curl for healthcheck
RUN apk add --no-cache curl tzdata

# Create dedicated non-root application user
RUN addgroup -S enxgroup && adduser -S enxuser -G enxgroup

# Copy node modules and application code
COPY --from=builder /app/node_modules ./node_modules
COPY . .

# Change ownership to non-root user
RUN chown -R enxuser:enxgroup /app

# Use non-root user
USER enxuser

# Expose backend API port
EXPOSE 5000

# Docker healthcheck pinging deep health endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:5000/health || exit 1

# Start production server
CMD ["node", "server.js"]
