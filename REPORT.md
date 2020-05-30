# Report

Authors :

- Alexandre **Piveteau**
- Guy-Laurent **Subri**

## Extra tooling used for the lab

In this lab, we've used a few extra tools, on top of Docker, NPM and an Apache2
HTTP Server. These additions include :

- [Elm](https://elm-lang.org), a pure functional programming language. It is
  replacing client-side Javascript when performing AJAX requests.
- [Serf](https://serf.io), a CLI interface to a distributed cluster management
  tool. We use it as a way to let servers discover each other, and keep track
  of the current topology.

## Details of our configuration

We're describing our configuration in its "final" state, with dynamic load
balancing and automated cluster topology detection. We've produced a total of
**3 Docker images** in this lab, as well as helper scripts to manage the state
of the cluster.

There are five helper scripts in the `./docker-images` folder :

+ `docker_up.sh` is the meat of the project, and starts the reverse proxy with
  load balancing. It will build all of the required images before launching
  only the remote proxy, in a container named `res-reverse-proxy`. Please make
  sure that no container is named that way before launching the system.
- `docker_down.sh` will kill all the Docker containers running on the
  system, and delete any container named `res-reverse-proxy`.
- `new_dynamic.sh` creates a new **dynamic server** container from the
  corresponding image, fetches the IP address of a **running** container named
  `res-reverse-proxy`, and passes it as an environment variable to the newly
  created container. This helps the container connect to the cluster.
- `new_static.sh` creates a new **static server** container from the
  corresponding image, fetches the IP address of a **running** container named
  `res-reverse-proxy`, and passes it as an environment variable to the newly
  created container. This helps the container connect to the cluster.
- `explore.sh` connects to a running container named `res-reverse-proxy.sh` and
  launches a `/bin/bash` shell. This is useful for debugging, or showing nice
  stuff to nice assistants.

Before running any of the four last commands, you must have started the named
`res-reverse-proxy` container. A typical usage sequence would be as follows :

```bash
> ./docker_up.sh
> # Wait a few seconds, until the proxy is up and running.
> ./new_static.sh
> ./new_dynamic.sh
> # This is a minimal configuration that produces the desired behavior.
> # (optional) ./new_static.sh adds a new static server.
> # (optional) ./new_dynamic.sh adds a new dynamic server.
> ./docker_down.sh
```

### Static HTTP Server

#### Building our static website
#### Serving static content
#### AJAX with [Elm](https://elm-lang.org)

### Dynamic HTTP Server

#### Building our Node app
#### Serving our Node app

### Dynamic Reverse Proxy

#### Forwarding routes
#### Detecting topology changes
#### Dynamic load balancing with [Serf](https://serf.io)
