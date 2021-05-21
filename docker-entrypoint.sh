#!/bin/sh
set -e

if [ "$1" = 'dockerd' ]; then
	# if we're running Docker, let's pipe through dind
	# (and we'll run dind explicitly with "sh" since its shebang is /bin/bash)
	set -- sh "$(which dind)" "$@"

	# explicitly remove Docker's default PID file to ensure that it can start properly if it was stopped uncleanly (and thus didn't clean up the PID file)
	rm -f /var/run/docker.pid
fi

if [ ! -z "$DOCKER_INSECURE_REGISTRY" ]; then
  mkdir -p /etc/docker

  echo "{" > /etc/docker/daemon.json
  echo "\"insecure-registries\" : [\"$DOCKER_INSECURE_REGISTRY\"]" >> /etc/docker/daemon.json
  echo "}">> /etc/docker/daemon.json
fi

echo "## Starting Jenkins Agent"
exec /usr/local/bin/jenkins-agent &

echo "## Starting Docker Container"
exec dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2375 --group=jenkins