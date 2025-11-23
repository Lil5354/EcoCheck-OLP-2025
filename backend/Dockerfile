# MIT License
# Copyright (c) 2025 Lil5354
# EcoCheck Backend Dockerfile

FROM node:18-alpine

WORKDIR /app

# Install needed tools
RUN apk add --no-cache curl wget netcat-openbsd postgresql-client

# Copy package files
COPY backend/package*.json ./

# Install dependencies (use npm install to avoid lockfile requirement)
RUN npm install --omit=dev

# Copy all necessary directories from the correct context
COPY backend/src/ ./src/
COPY backend/public/ ./public/
COPY db/ ./db/
COPY backend/entrypoint.sh ./

# Make entrypoint executable and convert line endings
RUN chmod +x entrypoint.sh && \
    dos2unix entrypoint.sh || sed -i 's/\r$//' entrypoint.sh

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Use entrypoint to run migrations and start app
ENTRYPOINT ["/bin/sh", "./entrypoint.sh"]