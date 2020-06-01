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

# Management user interface and backend
cd management-frontend
./build.sh
cd ..

cd management-backend
./build.sh
cd ..

# Run the reverse proxy on port local port 8080.
docker run -p 8080:80 --name res-reverse-proxy res/apache_rp &
