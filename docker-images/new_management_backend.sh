#!/bin/bash
IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' res-reverse-proxy)
echo $IP
docker run -v /var/run/docker.sock:/var/run/docker.sock -e EXISTING_NODE=$IP res/management-backend &
