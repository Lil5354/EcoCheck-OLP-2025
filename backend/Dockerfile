# MIT License
# Copyright (c) 2025 Lil5354
# EcoCheck Backend Dockerfile

FROM node:18-alpine

WORKDIR /app

# Install needed tools
RUN apk add --no-cache curl wget

# Copy package files
COPY package*.json ./

# Install dependencies (use npm install to avoid lockfile requirement)
RUN npm install --omit=dev

# Copy source code and public assets
COPY src/ ./src/
COPY public/ ./public/
COPY entrypoint.sh ./

# Make entrypoint executable
RUN chmod +x entrypoint.sh

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Start application
ENTRYPOINT ["./entrypoint.sh"]