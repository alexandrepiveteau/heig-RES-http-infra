# Report

Authors :

- Alexandre **Piveteau**
- Guy-Laurent **Subri**

## Extra tooling used for the lab

In this lab, we've used a few extra tools, on top of Docker, NPM and an Apache2
HTTP Server. These additions include :

- [Elm](elm-lang.org), a pure functional programming language. It is replacing
  client-side Javascript when performing AJAX requests.
- [Serf](serf.io), a CLI interface to a distributed cluster management tool. We
  use it as a way to let servers discover each other, and keep track of the
  current topology.

## Details of our configuration

We're describing our configuration in its "final" state, with dynamic load
balancing and automated cluster topology detection. We've produced a total of
**3 Docker images** in this lab.

### Static HTTP Server

#### Building our static website
#### Serving static content
#### AJAX with [Elm](elm-lang.org)

### Dynamic HTTP Server

#### Building our Node app
#### Serving our Node app

### Dynamic Reverse Proxy

#### Forwarding routes
#### Detecting topology changes
#### Dynamic load balancing with [Serf](serf.io)
