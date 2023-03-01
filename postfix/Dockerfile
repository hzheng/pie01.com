FROM ubuntu:20.04

RUN apt-get update && apt-get install -y postfix rsyslog mailutils
RUN echo '*.*   @rsyslog' >> /etc/rsyslog.conf

COPY run.sh /
RUN chmod +x /run.sh
RUN newaliases

#ENTRYPOINT ["/run.sh"]
CMD ["/run.sh"]
