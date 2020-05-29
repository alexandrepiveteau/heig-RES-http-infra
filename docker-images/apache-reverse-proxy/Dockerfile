FROM php:7.2-apache

RUN apt-get update && apt-get install -y vim serf

COPY apache2-foreground /usr/local/bin
COPY update_topology /usr/local/bin

COPY templates /var/apache2/templates

COPY conf-apache2/ /etc/apache2
COPY conf-serf/ /etc/serf

RUN a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests status
RUN a2ensite 000-* 
