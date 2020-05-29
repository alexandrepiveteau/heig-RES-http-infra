#!/bin/bash
IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' res-reverse-proxy)
docker run -e EXISTING_NODE=$IP res/apache_php &
