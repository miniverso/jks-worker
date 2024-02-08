ARG JAVA_VERSION=17.0.8.1_1
ARG ALPINE_TAG=3.19.1
FROM eclipse-temurin:"${JAVA_VERSION}"-jdk-alpine AS jre-build

RUN if [ "$TARGETPLATFORM" != 'linux/arm/v7' ]; then \
    case "$(jlink --version 2>&1)" in \
      # jlink version 11 has less features than JDK17+
      "11."*) strip_java_debug_flags="--strip-debug" ;; \
      *) strip_java_debug_flags="--strip-java-debug-attributes" ;; \
    esac; \
    jlink \
      --add-modules ALL-MODULE-PATH \
      "$strip_java_debug_flags" \
      --no-man-pages \
      --no-header-files \
      --compress=2 \
      --output /javaruntime; \
  else \
    cp -r /opt/java/openjdk /javaruntime; \
  fi

FROM docker:25-dind

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000

RUN addgroup -g "${gid}" "${group}" \
  && adduser -h /home/"${user}" -u "${uid}" -G "${group}" -D "${user}" || echo "user ${user} already exists."

ARG AGENT_WORKDIR=/home/"${user}"/agent

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'
ENV TZ=Etc/UTC

RUN apk add --no-cache \
      curl \
      bash \
      git \
      git-lfs \
      musl-locales \
      openssh-client \
      openssl \
      procps \
      tzdata \
      tzdata-utils \
    && rm -rf /tmp/*.apk /tmp/gcc /tmp/gcc-libs.tar* /tmp/libz /tmp/libz.tar.xz /var/cache/apk/*

ARG VERSION=3206.vb_15dcf73f6a_9
ADD --chown="${user}":"${group}" "https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar" /usr/share/jenkins/agent.jar
RUN chmod 0644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

ENV JAVA_HOME=/opt/java/openjdk
COPY --from=jre-build /javaruntime "$JAVA_HOME"
ENV PATH="${JAVA_HOME}/bin:${PATH}"

USER "${user}"
ENV AGENT_WORKDIR="${AGENT_WORKDIR}"
RUN mkdir -p /home/"${user}"/.jenkins && mkdir -p "${AGENT_WORKDIR}"

VOLUME /home/"${user}"/.jenkins
VOLUME "${AGENT_WORKDIR}"
WORKDIR /home/"${user}"
ENV user=${user}
LABEL \
    org.opencontainers.image.vendor="Jenkins project" \
    org.opencontainers.image.title="Official Jenkins Agent Base Docker image" \
    org.opencontainers.image.description="This is Grupo Loja base image, which provides the Jenkins agent executable (agent.jar) and a DinD" \
    org.opencontainers.image.version="${VERSION}" \
    org.opencontainers.image.url="https://www.jenkins.io/" \
    org.opencontainers.image.source="https://github.com/jenkinsci/docker-agent" \
    org.opencontainers.image.licenses="MIT"

USER root
RUN apk add --no-cache \
  zip \
  curl \
  bind-tools

ENV AGENT_VERSION=3206.vb_15dcf73f6a_9-3
RUN curl -LO -H 'Cache-Control: no-cache' "https://github.com/jenkinsci/docker-agent/blob/${AGENT_VERSION}/jenkins-agent" &&\
    mv jenkins-agent /usr/local/bin/jenkins-agent &&\
    chmod +x /usr/local/bin/jenkins-agent &&\
    ln -s /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-slave

ENV KUBECTL_VERSION=v1.29.1
RUN curl -LO -H 'Cache-Control: no-cache' "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
 && mv kubectl /usr/local/bin \
 && chmod +x /usr/local/bin/kubectl

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod u+x /docker-entrypoint.sh 

ENTRYPOINT ["/docker-entrypoint.sh"]