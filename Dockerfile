# ENX Money Backend — Production Dockerfile
# This file is required when Render is configured as Docker runtime.
# The render.yaml 'env: node' config uses the buildCommand/startCommand directly.
# Both approaches are supported.

FROM node:20-alpine

WORKDIR /app

# Install OS tools needed for healthcheck
RUN apk add --no-cache curl tzdata

# Install dependencies
COPY server/package*.json ./
RUN npm ci --only=production

# Copy application source
COPY server/ .

# Non-root user for security
RUN addgroup -S enxgroup && adduser -S enxuser -G enxgroup && \
    chown -R enxuser:enxgroup /app
USER enxuser

ENV NODE_ENV=production
ENV PORT=5000

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
  CMD curl -f http://localhost:5000/health || exit 1

CMD ["node", "server.js"]
