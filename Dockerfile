FROM docker.io/library/openjdk:8-slim

ENV BUILDER_VERSION=1.0 \
    BUILD_TYPE=Maven \
    PATH=/usr/local/bin/mvn:/usr/local/bin/gradle:$PATH \
    HOME=/opt/app-root/src

ARG MAVEN_VERSION=3.5.4
ARG GRADLE_VERSION=4.4

LABEL io.k8s.description="Platform for building Spring Boot applications with maven or gradle" \
      io.k8s.display-name="Spring Boot builder 1.0" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="Java,Spring Boot,builder" \
      io.openshift.s2i.scripts-url="image:///usr/libexec/s2i"

EXPOSE 8080

WORKDIR $HOME

CMD ["/usr/libexec/s2i/usage"]

COPY ./s2i/bin/ /usr/libexec/s2i

RUN apt-get update && \
   apt-get -y install curl && \
   apt-get clean && apt-get autoclean && \
   rm -rf /tmp/* /var/tmp/* && \
   rm -rf /var/lib/apt/lists/* && \
   rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin

RUN mkdir -p /opt/openshift && mkdir -p /opt/app-root/src && \
    chown -R 1000:1000 /opt/openshift /opt/app-root/src && \
    chmod -R 777 /opt/openshift /opt/app-root/src && \
    chmod -R 777 /usr/libexec/s2i

RUN (curl -fSL http://ftp.wayne.edu/apache/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | \
    tar -zx -C /usr/local) && \
    mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven && \
    ln -sf /usr/local/maven/bin/mvn /usr/local/bin/mvn && \
    mkdir -p $HOME/.m2 && chmod -R a+rwX $HOME/.m2

RUN curl -fSL https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip -o /tmp/gradle-$GRADLE_VERSION-bin.zip && \
    unzip /tmp/gradle-$GRADLE_VERSION-bin.zip -d /usr/local/ && \
    rm /tmp/gradle-$GRADLE_VERSION-bin.zip && \
    mv /usr/local/gradle-$GRADLE_VERSION /usr/local/gradle && \
    ln -sf /usr/local/gradle/bin/gradle /usr/local/bin/gradle && \
    mkdir -p $HOME/.gradle && chmod -R a+rwX $HOME/.gradle

USER 1000
