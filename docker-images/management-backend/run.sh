#!/bin/sh
docker run \
    -p 9091:3000 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    res/management-backend
