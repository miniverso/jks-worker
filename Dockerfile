FROM jenkins/inbound-agent as builder

FROM docker:20-dind

COPY --from=builder /usr/local/bin/jenkins-slave /usr/local/bin/jenkins-agent
COPY --from=builder /usr/share/jenkins/agent.jar /usr/share/jenkins/agent.jar

ARG user=jenkins
ARG group=jenkins
ARG uid=10000
ARG gid=10000

ARG AGENT_WORKDIR=/home/${user}/agent

USER root

ENV LANG C.UTF-8

ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk/jre
ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin

RUN apk add --no-cache \
        go \
        git \
        nss \
        img \
        gcc \
        make \
        bash \
        curl \
        glib \
        curl \
        sudo \
        bash \
        rust \
        yarn \
        unzip \
        cargo \
        nodejs \
        py-pip \
        procps \
        openssl \
        python2 \
        python3 \
        git-lfs \
        openssh \
        chromium \
        musl-dev \
        freetype \
        musl-dev \
        harfbuzz \
        openjdk8 \
        bind-tools \
        libffi-dev \
        nodejs-npm \
        python3-dev \
        openssl-dev \
        ttf-freefont \
        freetype-dev \
        openssh-client \
        ca-certificates \
        chromium-chromedriver

ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH

RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin \
  && go get github.com/github-release/github-release \
  && git clone https://github.com/minio/mc \
  && cd mc \
  && go install -v -ldflags "$(go run buildscripts/gen-ldflags.go)" \ 
  && cd -

RUN pip install --upgrade pip docker-compose \
  && addgroup -g ${gid} ${group} \
  && adduser -D -h $HOME -u ${uid} -G ${group} ${user} \
  && rm -rf /var/cache/apk/* \
  && chmod +x /usr/local/bin/jenkins-agent \
  && chmod 644 /usr/share/jenkins/agent.jar \
  && ln -s /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-slave \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar 

ENV SONAR_VERSION 4.6.2.2472
RUN mkdir -p /opt/sonnar \
 && curl -H 'Cache-Control: no-cache ' https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_VERSION}-linux.zip  -o sonar-scanner-cli-${SONAR_VERSION}-linux.zip \
 && unzip sonar-scanner-cli-${SONAR_VERSION}-linux.zip \
 && rm sonar-scanner-cli-${SONAR_VERSION}-linux.zip \
 && mv /sonar-scanner-${SONAR_VERSION}-linux /opt/sonnar \
 && ln -s /opt/sonnar/sonar-scanner-${SONAR_VERSION}-linux/bin/sonar-scanner /usr/local/bin/sonar-scanner \
 && chmod +x /usr/local/bin/sonar-scanner \
 && rm /opt/sonnar/sonar-scanner-${SONAR_VERSION}-linux/jre/bin/java \
 && ln -s /usr/bin/java /opt/sonnar/sonar-scanner-${SONAR_VERSION}-linux/jre/bin/java

RUN curl -LO -H 'Cache-Control: no-cache' "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" \
 && mv kubectl /usr/local/bin \
 && chmod +x /usr/local/bin/kubectl

ENV AGENT_WORKDIR=${AGENT_WORKDIR}
RUN mkdir -p /home/${user}/.jenkins \
  && mkdir -p ${AGENT_WORKDIR} \
  && chown ${user} /home/${user}/.jenkins \
  && chown ${user}  ${AGENT_WORKDIR}

USER ${user}
ENV HOME /home/${user}

VOLUME /home/${user}/.jenkins
VOLUME ${AGENT_WORKDIR}
WORKDIR /home/${user}

USER root
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod 755 /docker-entrypoint.sh 

ENTRYPOINT ["/docker-entrypoint.sh"]
