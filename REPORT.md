# Report

Authors :

- Alexandre **Piveteau**
- Guy-Laurent **Subri**

## Table of contents

<!-- vim-markdown-toc GFM -->

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
    * [Detecting topology changes](#detecting-topology-changes)
    * [Dynamic load balancing with Serf](#dynamic-load-balancing-with-serf)

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

#### Building our Node app
#### Serving our Node app

### Dynamic Reverse Proxy

#### Forwarding routes
#### Detecting topology changes
#### Dynamic load balancing with [Serf](https://serf.io)
