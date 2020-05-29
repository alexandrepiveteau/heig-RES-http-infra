#!/bin/bash
docker kill $(docker ps -q)
docker rm /res-reverse-proxy
