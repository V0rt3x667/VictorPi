FROM alpine:latest
LABEL maintainer="V0rt3x667 <al-g0l@outlook.com>"

COPY docker/setup.sh /usr/bin/

RUN apk update; apk add --no-cache bash; setup.sh

EXPOSE 2222
EXPOSE 8080

CMD ["victorpi.sh", "-h"]
