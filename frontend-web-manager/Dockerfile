# MIT License
# Copyright (c) 2025 Lil5354
# EcoCheck Frontend Web Manager Dockerfile

# Build stage
FROM node:22-alpine AS build

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies (include devDeps for build tools like Vite)
# Using npm install to refresh lock inside container since we modify deps dynamically
RUN npm install --no-audit --fund=false

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy built application
COPY --from=build /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
