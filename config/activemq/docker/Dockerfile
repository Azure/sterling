FROM openjdk:jdk-slim
RUN mkdir /opt/apache
WORKDIR /opt/apache
RUN apt-get update && apt-get install -y wget
RUN groupadd -r activemq && useradd -r -g activemq activemq
RUN chown -R activemq:activemq /opt/apache
USER activemq
RUN wget -O amq.tar.gz http://archive.apache.org/dist/activemq/5.17.1/apache-activemq-5.17.1-bin.tar.gz && tar -xvf amq.tar.gz
RUN  sed -i "s|127.0.0.1|0.0.0.0|g" apache-activemq-5.17.1/conf/jetty.xml
EXPOSE 8161 61616 5672 61613 1833
CMD ["/bin/sh","apache-activemq-5.17.1/bin/activemq","console"]