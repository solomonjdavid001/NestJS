# Stage 1: Builder
FROM node:20-slim AS builder

# Enable Corepack to manage package managers like pnpm
RUN corepack enable

# Set the working directory
WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install dependencies using pnpm with caching
RUN --mount=type=cache,id=pnpm,target=/root/.local/share/pnpm/store \
    pnpm fetch --frozen-lockfile && \
    pnpm install --frozen-lockfile

# Copy the rest of the application source code
COPY . .

# Build the NestJS application
RUN pnpm build

# Stage 2: Runner
FROM node:20-slim AS runner

# Enable Corepack
RUN corepack enable

# Set the working directory
WORKDIR /app

# Copy built files and package files from builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json /app/pnpm-lock.yaml ./

# Install only production dependencies
RUN pnpm install --frozen-lockfile --prod

# Expose the application port
EXPOSE 3000

# Start the application
CMD ["pnpm", "start:prod"]
