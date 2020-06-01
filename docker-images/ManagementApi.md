# Management API

## General

This API is available at `/management/api`. It can be accessed over HTTP.

## Methods

`GET /all`

- Lists all the containers of type `static` or `dynamic` in the cluster.
- Each container has an `identifier` and a `type`, which can be `static` or
  `dynamic`.

Example :

```json
[
  {
    "identifier"  : "some-text",
    "type"        : "static"
  },
  {
    "identifier"  : "something-else",
    "type"        : "dynamic"
  }
]
```

`DELETE /container/{identifier}`

- Kills the container with the provided identifier.
- The HTTP response is empty.

`POST /container/{type}`

- Creates a new container of the provided `type`, which can be `static` or
  `dynamic`.
- Returns the newly created container.

```json
{
  "identifier"  : "my-new-container",
  "type"        : "static"
}
```
