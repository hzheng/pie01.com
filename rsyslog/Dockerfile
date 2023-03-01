FROM alpine:3.14

RUN apk update

RUN apk add --no-cache rsyslog

COPY rsyslog.conf /etc/

ENTRYPOINT ["rsyslogd", "-n"]
