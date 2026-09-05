FROM alpine:3.19
RUN apk add curl
COPY . /app
CMD ["node", "app.js"]
