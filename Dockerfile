FROM node:18-alpine as builder
RUN npm install -g pnpm
WORKDIR /app
COPY . .
RUN if [ -f "./package-lock.json" ]; then npm install; \
    elif [ -f "./yarn.lock" ]; then yarn; \
    elif [ -f "./pnpm-lock.yaml" ]; then pnpm install;fi
COPY . .
RUN npm run build

FROM nginxinc/nginx-unprivileged:stable-alpine-slim

# Update nginx user/group in alpine
ENV ENABLE_PERMISSIONS=TRUE
ENV DEBUG_PERMISSIONS=TRUE
ENV USER_NGINX=10015
ENV GROUP_NGINX=10015

COPY --from=builder /app/default.conf /etc/nginx/conf.d/default.conf

USER root
RUN ln -sf /app/public/ /usr/share/nginx/html/
USER nginx
COPY --from=builder /app/build /usr/share/nginx/html/
USER 10015
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]