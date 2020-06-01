# Report

Authors :

- Alexandre **Piveteau**
- Guy-Laurent **Subri**

# Table of Contents

- [Report](#report)
- [Table of Contents](#table-of-contents)
    - [Extra tooling used for the lab](#extra-tooling-used-for-the-lab)
    - [Details of our configuration](#details-of-our-configuration)
        - [Static HTTP Server](#static-http-server)
            - [Building our static website](#building-our-static-website)
            - [Serving static content](#serving-static-content)
            - [AJAX with Elm](#ajax-with-elm)
                - [Integration in HTML content](#integration-in-html-content)
                - [AJAX in Elm](#ajax-in-elm)
        - [Dynamic HTTP Server](#dynamic-http-server)
            - [Building our Node app](#building-our-node-app)
            - [Serving our Node app](#serving-our-node-app)
        - [Dynamic Reverse Proxy](#dynamic-reverse-proxy)
            - [Forwarding routes](#forwarding-routes)
            - [Building the reverse proxy](#building-the-reverse-proxy)
            - [Load balancing with and without sticky sessions](#load-balancing-with-and-without-sticky-sessions)
                - [Round-robin balancer for a dynamic site](#round-robin-balancer-for-a-dynamic-site)
                - [Sticky balancer for a static site](#sticky-balancer-for-a-static-site)
            - [Detecting topology changes with Serf](#detecting-topology-changes-with-serf)
            - [Dynamic load balancing with Serf](#dynamic-load-balancing-with-serf)
                - [Writing the `001-reverse-proxy.conf` file](#writing-the-001-reverse-proxyconf-file)
                - [Wrapping it up](#wrapping-it-up)
        - [Docker management](#docker-management)

* [Extra tooling used for the lab](#extra-tooling-used-for-the-lab)
* [Details of our configuration](#details-of-our-configuration)
  * [Static HTTP Server](#static-http-server)
    * [Building our static website](#building-our-static-website)
    * [Serving static content](#serving-static-content)
    * [AJAX with Elm](#ajax-with-elm)
      * [Integration in HTML content](#integration-in-html-content)
      * [AJAX in Elm](#ajax-in-elm)
  * [Dynamic HTTP Server](#dynamic-http-server)
    * [Building our Node app](#building-our-node-app)
    * [Serving our Node app](#serving-our-node-app)
  * [Dynamic Reverse Proxy](#dynamic-reverse-proxy)
    * [Forwarding routes](#forwarding-routes)
    * [Building the reverse proxy](#building-the-reverse-proxy)
    * [Load balancing with and without sticky sessions](#load-balancing-with-and-without-sticky-sessions)
      * [Round-robin balancer for a dynamic site](#round-robin-balancer-for-a-dynamic-site)
      * [Sticky balancer for a static site](#sticky-balancer-for-a-static-site)
    * [Detecting topology changes with Serf](#detecting-topology-changes-with-serf)
    * [Dynamic load balancing with Serf](#dynamic-load-balancing-with-serf)
      * [Writing the `001-reverse-proxy.conf` file](#writing-the-001-reverse-proxyconf-file)
      * [Wrapping it up](#wrapping-it-up)

<!-- vim-markdown-toc -->

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

Our static HTTP server is based on the `php:apache` image presented in the
webcasts. It uses a Docker multi-stage build, to perform the following steps :

1. Installing NPM and our build dependencies.

```Dockerfile
# Build the elm app. We first install the npm modules, to profit from Docker caching.
FROM node:14 AS build
WORKDIR /code
COPY package.json .
COPY package-lock.json .
RUN npm install
```

2. Compiling our Elm program into an index.js file.
```Dockerfile
COPY . .
RUN npm run build
RUN cp ./index.js /code/static
```

3. Copying the `index.js` and HTML + CSS content into the `php:apache` image
   to create our own image.

```Dockerfile
# Serve the web app with a static Apache server.
FROM php:7.2-apache
RUN apt-get update && apt-get install -y vim serf
COPY --from=build code/static/ /var/www/html/

# Configure serf and startup script.
COPY apache2-foreground /usr/local/bin
COPY conf-serf/ /etc/serf
```

At this stage, we also set up the `apache2-foreground` script (which is
normally used by the `php:apache` image to launche Apache2 in the foreground)
to support our dynamic reverse proxy configurartion. More on that later.

#### Serving static content

Our Apache2 configuration simply serves content that's put in `/var/www/html`
in the container. This behavior is inherited from the `php:image`.

#### AJAX with [Elm](https://elm-lang.org)

To implement some AJAX requests, we decided to use a pure functional
programming language that compiles to Javascript – [Elm](https://elm-lang.org).
We use an Elm [`Browser.element`](https://package.elm-lang.org/packages/elm/browser/latest/Browser)
to embed our program in a static HTML page.

##### Integration in HTML content

Assuming the Elm script has been compiled into an `index.js` file, it's pretty
trivial to include it in a static HTML page :

```html
<html>
<head>
  ...
  <script type="text/javascript" src="index.js"></script>
  ...
</head>
<body>
  ...
  <!-- This is where the Elm component will live -->
  <div id="myapp"></div>
  ...
</body>

<!-- It's important that this piece of code is at the end of the page -->
<script type="text/javascript">
    var app = Elm.Main.init({
      node: document.getElementById('myapp')
    });
</script>
</html>
```

The Elm app will then create its own DOM and **replace** the `div` with the
`myapp` identifier.

Here are some key takeaways of how Elm works, and useful resources :

- [Elm apps use pure functions to describe side effects and mutations](https://guide.elm-lang.org/architecture/)
- [HTML content is described within Elm, and managed by a virtual DOM](https://guide.elm-lang.org/architecture/buttons.html)
- [Elm apps use ports to interop with Javascript](https://guide.elm-lang.org/interop/ports.html)

Since our app is very simple, it does not need to interact with Javascript, and
can perform AJAX requests directly.

##### AJAX in Elm

Our Elm code, present in the `src` folder, contains two files :

- `Main.elm`, which contains the program logic and entrypoint.
- `Api.elm`, which centralizes the code that describes the HTTP requests made
  and the `Json.Decoder` associated with the content.

The `view` code renders the current content of the `Model` :

```elm
view : Model -> Html Message
view model =
    Html.div [ Attribute.class "container cards" ]
        (List.map card model)


card : Api.Transaction -> Html Message
card transaction =
    Html.div [ Attribute.class "card" ]
        [ Html.div [ Attribute.class "skill-level" ]
            [ Html.span [] [ Html.text "we like" ]
            , Html.h2 [] [ Html.text "Elm" ]
            ]
        , Html.div [ Attribute.class "skill-meta" ]
            [ Html.h3 [] [ Html.text transaction.title ]
            , Html.span []
                [ Html.text <| "Amount is " ++ String.fromFloat transaction.amount ]
            ]
        ]
```

The `update` code describes the "mutations" that our application supports. In
this case, we can ask for transactions (aka ask to make an **api request**),
get an error following a request, or get a list of transactions :

```elm
type Message
    = GotTransactions (List Api.Transaction)
    | GotError
    | RequestTransactions


update : Message -> Model -> ( Model, Cmd Message )
update message existing =
    case message of
        GotTransactions transactions ->
            ( transactions, Cmd.none )

        GotError ->
            ( [], Cmd.none )

        RequestTransactions ->
            ( existing, Cmd.map resultToMessage Api.request )
```

This works with the `subscriptions`, which describe, in a **managed effect**,
that we want to request the list of transactions **every 5 seconds** :


```elm
subscriptions : Model -> Sub Message
subscriptions _ =
    Time.every (5 * 1000) (always RequestTransactions)
```

Finally, in the `Api.elm` module, we first have some code that describes how
to transform a `Json.Decode.Value` into a `Transaction` record :

```elm
type alias Transaction =
    { amount : Float
    , title : String
    }


{-| Helps decode a Json.Decode.Value into a Transaction record.
-}
decoder : Json.Decode.Decoder Transaction
decoder =
    Json.Decode.map2 Transaction
        (Json.Decode.field "amount" Json.Decode.float)
        (Json.Decode.field "title" Json.Decode.string)
```

As well as the code that describes a **managed effect** to perform a `GET`
request over HTTP to our `/api/transactions/` endpoint :

```elm
{-| Requests a List Transaction from the api server.
-}
request : Cmd (Result Http.Error (List Transaction))
request =
    Http.get
        { url = "/api/transactions/"
        , expect =
            Http.expectJson identity <|
                Json.Decode.list decoder
        }
```

As will all **(managed) effects** in Elm, calling this function does not
perform any side-effect – an HTTP request will only be performed if the
`Cmd` is returned as part of a call to the `update` function, and the
resulting content will then be dispatched within a `Message`.

### Dynamic HTTP Server

Out dynamic HTTP server is based on **Node**, and uses **NPM** as its package
manager. The behavior of the app is relatively simple :

1. A dynamic web server listens for HTTP requests on the **port 3000**.
2. Whenever a request arrives at the `/` url, a list of transactions is
   randomly generated, and returned as some JSON-encoded data in the HTTP
   response.

#### Building our Node app

We use NPM to retrieve the two dependencies of our project. The configuration
is described in the `src/package.json` file :

- `chance` is a small library that generates "cool" random values for many
  data types.
- `express` is a simple web framework for building HTTP servers.

The `package-lock.json` file stores the versions of the libraries, as well as
some meta-data about their dependencies, and more stuff related to the project.

The configuration in the `Dockerfile` is as follows :

```Dockerfile

FROM node:14

RUN apt-get update && apt-get install -y vim serf
COPY src/ /opt/app
WORKDIR /opt/app
RUN npm install
```

creates a new image form the base `node` image, installs some utilities,
copies all of the code content in `/opt/app`, and runs `npm install` to fetch
all the required dependencies.

Similarly to the static image, serf is configured too :

```Dockerfile
# Configure serf and startup script.
COPY conf-serf/ /etc/serf
COPY connect .
```

Finally, a `connect` script is run, that performs two operations :

```Dockerfile
CMD "./connect"
```

1. Starting the serf agent to monitor topology
2. Run the node.js app

```bash
#!/bin/bash
serf agent -config-file=/etc/serf/config -protocol=4 -join=$EXISTING_NODE &
node index.js
```

We must use a dedicated shell script to perform these operations, since we
can't directly ask Docker to perform multiple `CMD`.

#### Serving our Node app

Express simplifies the handling of HTTP requests quite a bit : we simply have
to tell it that we're listening on port 3000, and it will manage an HTTP server
for us :

```js
var Express = require('express');
var app = new Express();
app.listen(3000, function() {
  console.log('Listening on the port 3000');
});
```

We then specify the route for which we want to provide some answers :

```js
app.get('/', function(req, res) {
  console.log("Received a request !");
  res.send(generateTransactions());
});
```

> Logging that we receive requests is optional, but makes it easier to check
> whether a round-robin or a sticky policy is applied when we use a cluster of
> dynamic notes.

Finally, we can use `chance` to generate random transactions :

```js
var Chance = require('chance');
var chance = new Chance();
function generateTransactions() {
  var numberOfTransactions = chance.integer({min: 15, max: 25});
  var transactions = [];
  for (var i = 0; i < numberOfTransactions; i++) {
    var currency = chance.currency().code;
    var time = chance.date();
    var amount = chance.integer({min: 100, max: 10000}) / 100.0;
    var title = chance.sentence();
    transactions.push({
      currency : currency,
      time : time,
      amount : amount,
      title : title
    });
  }
  return transactions;
}
```

The returned objects will be of the form :


```json
{
  "currency"  : "LTL",
  "time"      : "2072-08-07T16:53:12.504Z",
  "amount"    : 84.16,
  "title"     : "Lorem ipsum"
}
```

Please note that we will not consume all of this data in the Elm component of
the static page.

### Dynamic Reverse Proxy

To combine our static and dynamic servers, we use a **dynamic reverse proxy**
with dynamic load balancing. The usage of a reverse proxy is necessary because
of the [**same origin policy**](https://en.wikipedia.org/wiki/Same-origin_policy)
that is applied to our infrastructure : the static Javascript served from the
static servers may only make requests to the same host, with the same port
number.

> We could also use a more advanced CORS policy instead, but this goes out of
> the scope of this lab.

The reverse proxy creates two load balancers :

- A **sticky** load balancer for the static content, which uses HTTP Cookies
  as a way to remember which route was used.
- A **round-robin** load balancer for the dynamic content, which does not need
  and alterations of the performed requests.

The reverse proxy uses the same `php:apache` base image as before, with
the [serf](https://serf.io) tool configured to listen for topology changes.

#### Forwarding routes

Requests are proxied to our two load balancers depending on whether their
route is matched by the api (`/api/transactions`) or by the static server
(everything else).

1. The requests for the `/api/transactions` are proxied first :

```apacheconf
ProxyPass '/api/transactions' 'balancer://dynamic-balancer'
ProxyPassReverse '/api/transactions' 'balancer://dynamic-balancer'
```

2. Followed by the more general requests to the static servers :

```apacheconf
ProxyPass '/' 'balancer://static-balancer/'
ProxyPassReverse '/' 'balancer://static-balancer/'
```

The two load balancers that the requests are proxied have the names
`dynamic-balancer` and `static-balancer`.

#### Building the reverse proxy

We still use the `php:apache` image in our `Dockerfile`. The build script
performs the following steps :

1. Install `vim` and `serf`.

```Dockerfile
FROM php:7.2-apache

RUN apt-get update && apt-get install -y vim serf
```

2. Copy the various files that we need (init scripts and topology update
   scripts). We'll cover those later.

```Dockerfile
COPY apache2-foreground /usr/local/bin
COPY update_topology /usr/local/bin

COPY templates /var/apache2/templates

COPY conf-apache2/ /etc/apache2
COPY conf-serf/ /etc/serf
```

3. Enable different Apache modules that we need for our configuration. More
   specifically :

* We use some helper modules,

```Dockerfile
# Helper modules.
RUN a2enmod status rewrite
```

  * We use some standard modules for proxying (as described in the webcasts),

```Dockerfile
# Proxy modules.
RUN a2enmod proxy proxy_http
```

  * And we enable some modules required for load balancing. `headers` lets us
    add some new HTTP headers (in particular a `Set-Cookie` header),
    `proxy-balancer` enables load balancers for a proxy, and
    `lmethod_byrequests` lets us use a load balancing method that's accounting
    for the number of requests sent to each server.

```Dockerfile
# Load balancing modules.
RUN a2enmod headers proxy_balancer lbmethod_byrequests
```

4. Finally, we enable a default site that performs nothing for queries to a
   host different than `labo.res.ch`.

```Dockerfile
# Enable the default site.
RUN a2ensite 000-*
```

#### Load balancing with and without sticky sessions

Load balancing comes in two flavors in our project :

- A **sticky** variant, for the static servers, that tries to always let the
  same clients make requests to the same machines.
- A quota-based **round-robin** variant, for the dynamic servers, that tries to
  assign the request to a machine whose quota of requests is not expired yet.

Both of these variants must be described in the
`/etc/apache2/sites-available/001-reverse-proxy.conf` file in the running
container.

##### Round-robin balancer for a dynamic site

The implementation is relatively straightforward : if you know the IPs of all
of the sites, you can implement the following rule :

```apacheconf
# Round-robin load balancer, with no routing cookie.
<Proxy balancer://dynamic-balancer>
  BalancerMember http://172.17.0.3:3000
  BalancerMember http://172.17.0.4:3000
  ProxySet lbmethod=byrequests
</Proxy>
```

The load balancing method is specified for the whole load balancer (in this
case `byrequests`).

##### Sticky balancer for a static site

On top of giving the list of the IPs that the requests should be distributed
to, some additional information is provided when it comes to how the requests
should be distributed.

```apacheconf
# Sticky load balancer (as long as the topology does not change too often).
Header add Set-Cookie "ROUTEID=.%{BALANCER_WORKER_ROUTE}e; path=/" env=BALANCER_ROUTE_CHANGED
<Proxy balancer://static-balancer>
  BalancerMember http://172.17.0.5:80 route=1
  BalancerMember http://172.17.0.6:80 route=2
  ProxySet stickysession=ROUTEID
</Proxy>
```

Specifically, a dedicated cookie `ROUTEID` will be added when the route that is
used by a certain client is changed. Whenever an ulterior request is made, the
`stickysession=ROUTEID` line will make the reverse proxy try to match the value
of the previously used route, and will direct this request to the server with
a matching `route=` parameter.

#### Detecting topology changes with [Serf](https://serf.io)

Topology of our cluster might change over time, especially if new nodes are
added, or existing nodes are killed. We use [serf](https://serf.io), a CLI,
to monitor the state of our cluster.

More specifically, each container that we start has `serf` started in the
background when it is launched (usually in the `apache2-foreground` or the
`connect` script) :

```bash
serf agent -config-file=/etc/serf/config -protocol=4 &
```

> Notice that we specify the `serf` protocol version. For some obscure reason,
> the serf protocol version `5` did not work on all the images, so we had to
> result to a slightly older version. This does not affect functionality at
> all.

Each container is also given a role that's either :

- `static`, for static website servers.
- `dynamic`, for dynamic website servers.
- `load-balancer`, for our central load balancer.

Roles are specified in a `sef-conf/conf` file that's copied in `/etc/serf/`
in each container. This is the configuration of a static node for instance :

```json
{
  "tags": {
    "role": "static"
  }
}
```

This way, running the `serf members` command from one of the nodes (assuming
they have been connected to the same cluster) will result in an output similar
to this :

```text
1c6982e4b271  172.17.0.3:7946  alive  role=dynamic
861fdf114a43  172.17.0.4:7946  alive  role=dynamic
4b8658c05fe0  172.17.0.5:7946  alive  role=static
6a21f8f5f792  172.17.0.6:7946  alive  role=static
9a8216c2c041  172.17.0.2:7946  alive  role=load-balancer
```

This contains the IP addresses and protocol where serf is running, the status
of the nodes, their roles, and their identifiers.

#### Dynamic load balancing with [Serf](https://serf.io)

Serf offers a way to automatically run a script whenever the topology changes.
We use this mechanism to update the Apache configuration file for our reverse
proxy dynamically. More specifically, using the following serf configuration on
the reverse proxy :

```json
{
  "tags": {
    "role": "load-balancer"
  },
  "event_handlers": [
    "cat | /usr/local/bin/update_topology"
  ]
}
```

The `update_topology` script is run whenever a topology change occurs :

```bash
#!/bin/bash
transformed=$(serf members | php /var/apache2/templates/config-template-serf.php)

echo "$transformed" > /etc/apache2/sites-available/001-reverse-proxy.conf
service apache2 reload
a2ensite 001-*
```

The script retrieves the `stdout` content of the `serf members` command, pipes
it into a `php` script (a template of the load balancers configuration), and
writes it in the `001-reverse-proxy.conf` file. The apache2 server is then
**reloaded** and the site **re-enabled**.

##### Writing the `001-reverse-proxy.conf` file

We use PHP as a templating engine for the `001-reverse-proxy.conf` file. More
specifically, since we pipe in the `serf members` input, we can filter the
different members by role and availability to decide to include them or not in
the reverse proxy configuration.

The PHP template has some functions that map a member line to its IP adress,
that map a member line to its agent role, and creates two variables
`$static_ips` and `$dynamic_ips` that contain the list of all the **alive
agents** with the right role. It's then easy to populate the `dynamic-balancer`
and the `static-balancer` with the right IPs :

```php
# Round-robin load balancer, with no routing cookie.
<Proxy balancer://dynamic-balancer>
<?php
foreach($dynamic_ips as $ip) {
  echo "    BalancerMember http://";
  echo $ip;
  echo ":3000\n";
}
?>
ProxySet lbmethod=byrequests
</Proxy>
```

```php
# Sticky load balancer (as long as the topology does not change too often).
Header add Set-Cookie "ROUTEID=.%{BALANCER_WORKER_ROUTE}e; path=/" env=BALANCER_ROUTE_CHANGED
<Proxy balancer://static-balancer>
<?php
$route = 1;
foreach($static_ips as $ip) {
  echo "    BalancerMember http://";
  echo $ip;
  echo ":80 route=";
  echo $route;
  echo "\n";
  $route = $route + 1;
}
?>
ProxySet stickysession=ROUTEID
</Proxy>
```

> Route ids for the sticky load balancer are not stable over time, if the
> topology changes. In our context, this is not a real problem, and if we
> wanted an actually more elaborate solution, we might want to use a dedicated
> tool to handle these problems for us.

##### Wrapping it up

To let the containers connect to each other, they must know the IP address of
at least one other container when launching their local `serf` instance. This
information is passed as an environment variable, `$EXISTING_NODE`, when the
containers are started. The different `./docker_up.sh`, `./new_static.sh`
and `./new_dynamic.sh` automate this manual setup.

### Docker management

To launch the docker management ui, run the `management.sh` script. It will launch a
container with [portainer](https://www.portainer.io/).
