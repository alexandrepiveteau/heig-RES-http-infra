FROM node:14

RUN apt-get update && apt-get install -y vim serf
COPY src/ /opt/app
WORKDIR /opt/app
RUN npm install

# Configure serf and startup script.
COPY conf-serf/ /etc/serf
COPY connect .

CMD "./connect"
