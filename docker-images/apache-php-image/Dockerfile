# Build the elm app. We first install the npm modules, to profit from Docker caching.
FROM node:14 AS build
WORKDIR /code
COPY package.json .
COPY package-lock.json .
RUN npm install
COPY . .
RUN npm run build
RUN cp ./index.js /code/static

# Serve the web app with a static Apache server.
FROM php:7.2-apache
RUN apt-get update && apt-get install -y vim serf
COPY --from=build code/static/ /var/www/html/

# Configure serf and startup script.
COPY apache2-foreground /usr/local/bin
COPY conf-serf/ /etc/serf
