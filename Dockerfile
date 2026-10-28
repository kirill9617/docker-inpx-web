FROM node:lts-alpine AS builder

ARG INPX_RELEASE

WORKDIR /build
RUN apk add --no-cache git zip 
RUN  git clone https://github.com/00svd00/inpx-web.git . && \
    if [ -n "${INPX_RELEASE}" ]; then git checkout "${INPX_RELEASE}"; fi
RUN npm ci 
RUN  npm run build:client
RUN  node build/prepkg.js linux 
RUN  npm run build:bundle
RUN  ./node_modules/.bin/pkg -t node24-alpine-x64 -C GZip --options max-old-space-size=4098,expose-gc -o dist/linux/inpx-web dist/bundle/index.js


FROM node:lts-alpine
RUN apk add --no-cache 7zip
# add local files
WORKDIR /app
COPY --from=builder /build/dist/linux/inpx-web  /app/inpx-web
RUN mkdir /library /data && touch /catalog.inpx && chmod +x /app/inpx-web

# ports and volumes
EXPOSE 12380

VOLUME /library
VOLUME /data
VOLUME /catalog.inpx

CMD ["/app/inpx-web", "--lib-dir=/library", "--data-dir=/data", "--inpx=/catalog.inpx",  "--host=0.0.0.0", "--port=12380" ]
