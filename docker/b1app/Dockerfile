FROM node:22-alpine
WORKDIR /app

# Install dependencies first for layer caching
COPY services/B1App/package.json services/B1App/package-lock.json ./
# npm install (not ci) — upstream lock file drifts frequently
RUN npm install --legacy-peer-deps && npm run postinstall

# Copy build config (not hot-reloaded)
COPY services/B1App/next.config.mjs services/B1App/tsconfig.json ./
COPY services/B1App/sentry.edge.config.ts services/B1App/sentry.server.config.ts ./

# src/ and public/ are volume-mounted at runtime for HMR
EXPOSE 3301

# `npm run dev` = `next dev -p 3301`
CMD ["npm", "run", "dev"]
