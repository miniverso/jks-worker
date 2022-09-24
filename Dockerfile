FROM jenkins/inbound-agent as builder

FROM docker:20-dind-rootless

COPY --from=builder /usr/local/bin/jenkins-slave /usr/local/bin/jenkins-agent
COPY --from=builder /usr/share/jenkins/agent.jar /usr/share/jenkins/agent.jar

ARG user=jenkins
ARG group=jenkins
ARG uid=10000
ARG gid=10000

ARG AGENT_WORKDIR=/home/${user}/agent

USER root

ENV LANG C.UTF-8

RUN apk add --no-cache \
        go \
        git \
        nss \
        img \
        npm \
        gcc \
        make \
        bash \
        curl \
        lftp \
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
        python3 \
        git-lfs \
        musl-dev \
        freetype \
        musl-dev \
        harfbuzz \
        openjdk11 \
        bind-tools \
        libffi-dev \
        python3-dev \
        openssl-dev \
        mysql-client \
        ca-certificates 

ENV JAVA_HOME /usr/lib/jvm/default-jvm/jre
ENV PATH $PATH:/usr/lib/jvm/default-jvm/jre/bin

ENV HELM_VERSION=3.7.2
ENV HELM_BASE_URL="https://get.helm.sh"
RUN case `uname -m` in \
        x86_64) HELM_ARCH=amd64; ;; \
        armv7l) HELM_ARCH=arm; ;; \
        aarch64) HELM_ARCH=arm64; ;; \
        ppc64le) HELM_ARCH=ppc64le; ;; \
        s390x) HELM_ARCH=s390x; ;; \
        *) echo "un-supported arch, exit ..."; exit 1; ;; \
    esac && \
    apk add --update --no-cache wget git && \
    wget ${HELM_BASE_URL}/helm-v${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz -O - | tar -xz && \
    mv linux-${HELM_ARCH}/helm /usr/bin/helm && \
    chmod +x /usr/bin/helm && \
    rm -rf linux-${HELM_ARCH}

RUN chmod +x /usr/bin/helm

RUN alias ftp=lftp \
  && alias s3="aws --endpoint-url https://eu2.contabostorage.com s3"

RUN cd /tmp \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && cd -

ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH

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
  && chown -R ${user} /home/${user} \
  && chown ${user}  ${AGENT_WORKDIR} 

USER ${user}
ENV HOME /home/${user}

VOLUME /home/${user}/.jenkins
VOLUME ${AGENT_WORKDIR}
WORKDIR /home/${user}
RUN mkdir ~/.mc && mkdir ~/.docker

USER root
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod 755 /docker-entrypoint.sh 

ENTRYPOINT ["/docker-entrypoint.sh"]
