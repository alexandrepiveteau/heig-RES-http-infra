#!/bin/sh
docker run \
    -p 9000:9000 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    portainer/portainer &
