#!/bin/bash
IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' res-reverse-proxy)
echo $IP
docker run -e EXISTING_NODE=$IP res/management-frontend &
