FROM node:22-alpine
WORKDIR /app

# Install dependencies first for layer caching
COPY services/Api/package.json services/Api/package-lock.json ./
RUN npm ci

# Copy static config and tooling (not hot-reloaded)
COPY services/Api/config/ ./config/
COPY services/Api/tsconfig.json services/Api/tsconfig.prod.json ./
COPY services/Api/eslint.config.js ./
# Copy jest config as .cjs (upstream uses module.exports but package.json has "type": "module")
COPY services/Api/jest.config.js ./jest.config.cjs
COPY services/Api/tools/ ./tools/

# src/ is volume-mounted at runtime for hot-reload
EXPOSE 8084 8087

CMD ["npx", "tsx", "watch", "src/index.ts"]
