FROM node:22-alpine
WORKDIR /app

RUN npm install -g nodemon ts-node typescript

COPY services/LessonsApi/package.json services/LessonsApi/package-lock.json ./
RUN npm ci

COPY services/LessonsApi/config/ ./config/
COPY services/LessonsApi/tsconfig.json ./
COPY services/LessonsApi/tools/ ./tools/

# src/ is volume-mounted at runtime
EXPOSE 8090

CMD ["nodemon", "--watch", "src", "-e", "ts,ejs", "--exec", "ts-node src/index.ts"]
