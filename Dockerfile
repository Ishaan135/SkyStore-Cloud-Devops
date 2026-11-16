# ---------- Stage 1: build the Vite/React app ----------
FROM node:22-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install --no-audit --no-fund
COPY . .
# Convex deployment URL is baked in at build time by Vite.
# If no build arg is given, fall back to the value in .env (an empty ARG would override it).
ARG VITE_CONVEX_URL
RUN if [ -z "$VITE_CONVEX_URL" ]; then unset VITE_CONVEX_URL; fi; npm run build

# ---------- Stage 2: serve with nginx ----------
FROM nginx:alpine
COPY demo/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1
CMD ["nginx", "-g", "daemon off;"]
