FROM node:22-alpine
WORKDIR /app

RUN npm install -g nodemon

COPY services/AskApi/package.json services/AskApi/package-lock.json ./
RUN npm ci

COPY services/AskApi/config/ ./config/
COPY services/AskApi/tsconfig.json ./
COPY services/AskApi/tools/ ./tools/
COPY services/AskApi/register.js ./

# src/ is volume-mounted at runtime
EXPOSE 8097

CMD ["nodemon", "--watch", "src", "-e", "ts,ejs", "--exec", "node --import ./register.js src/index.ts"]
