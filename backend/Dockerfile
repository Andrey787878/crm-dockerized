FROM node:20-alpine3.19 AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .

RUN npm prune --production


FROM node:20-alpine3.19

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=builder --chown=appuser:appgroup /app ./

ENV NODE_ENV=production

USER appuser

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:3001/api/clients || exit 1

CMD ["node", "server.js"]
