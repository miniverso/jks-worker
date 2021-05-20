FROM jenkins/inbound-agent:latest-jdk11

USER root
RUN curl -sSL https://cli.openfaas.com | sh

USER jenkins