FROM icr.io/ibm-messaging/mq
USER root
COPY queue-config.mqsc /etc/mqm/
COPY jms-config.txt /var/mqm
RUN chown 1001:root /var/mqm/jms-config.txt
USER 1001
RUN sed -i 's|PROVIDER_URL=.*|PROVIDER_URL=file:///var/mqm/|g' /opt/mqm/java/bin/JMSAdmin.config