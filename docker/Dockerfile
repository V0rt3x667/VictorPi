FROM alpine:latest
LABEL maintainer="V0rt3x667 <al-g0l@outlook.com>"

COPY scripts/victorpi.sh scripts/setup.sh /usr/bin/
COPY scripts/*.sh /opt/victorpi/

RUN apk update; apk add --no-cache bash; setup

EXPOSE 2222
EXPOSE 8080

CMD ["victorpi.sh", "-h"]
