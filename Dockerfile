FROM gliderlabs/alpine

MAINTAINER Ofer Velich <ofer@logz.io>

RUN apk --update add bash perl rsyslog

RUN mkdir /etc/rsyslog.d/
RUN mkdir /var/spool/rsyslog/

EXPOSE 514/tcp 514/udp

ADD scripts/* /root/
ADD files/* /root/files/

ENTRYPOINT /root/go.bash
