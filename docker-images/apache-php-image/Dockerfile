# Build the elm app.
FROM node:14 AS build
WORKDIR /code
COPY package.json .
COPY package-lock.json .
RUN npm install
COPY . .
RUN npm run build
RUN cp ./index.js /code/static

FROM php:7.2-apache
RUN apt-get update && apt-get install -y vim
COPY --from=build code/static/ /var/www/html/
