FROM php:7.2-apache

RUN apt-get update && apt-get install -y vim serf

COPY apache2-foreground /usr/local/bin
COPY update_topology /usr/local/bin

COPY templates /var/apache2/templates

COPY conf-apache2/ /etc/apache2
COPY conf-serf/ /etc/serf

# Helper modules.
RUN a2enmod status rewrite

# Proxy modules.
RUN a2enmod proxy proxy_http  

# Load balancing modules.
RUN a2enmod headers proxy_balancer lbmethod_byrequests

# Enable the default site.
RUN a2ensite 000-* 
