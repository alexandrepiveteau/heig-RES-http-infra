#!/bin/bash
cd apache-php-image
./build.sh
cd ..

cd apache-reverse-proxy
./build.sh
cd ..

cd express-image
./build.sh
cd ..

# First off, we run the reverse proxy, and retrieve its IP address.
docker run -p 8080:80 --name res-reverse-proxy res/apache_rp &
