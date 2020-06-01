var ip      = require('ip');
var Express = require('express');
var Docker  = require('dockerode');
var fs      = require('fs');
var socket  = process.env.DOCKER_SOCKET || '/var/run/docker.sock';
var stats   = fs.statSync(socket);

if (!stats.isSocket()) {
  throw new Error('Are you sure the docker is running?');
}

var docker = new Docker({socketPath: socket });

var app = new Express();

app.get('/', function(req, res) {
    console.log("Received a request !");
    res.send({});
});

app.get('/all', function(req, res) {
    docker.listContainers({all: false}, function(err, containers) {
        var result = [];
        containers.forEach(function (containerInfo) {
            let data = {
              identifier : containerInfo.Id,
              type : "static"
            };
            if (containerInfo.Image == "res/apache_php") {
              data.type = "static";
              result.push(data);
            } else if (containerInfo.Image == "res/express_myapp") {
              data.type = "dynamic";
              result.push(data);
            }
        });
        res.send(result);
    });
});

app.delete('/container/:id', function(req, res) {
  docker.getContainer(req.params.id).kill();
  res.send({});
});

app.post('/container/:type', function(req, res) {
  if (req.params.type == "static") {
    docker.createContainer({
      Image: 'res/apache_php',
      Env: [
        'EXISTING_NODE=' + ip.address()
      ]
    }).then(function(container) {
      container.start();
      res.send({});
    });
  } else if (req.params.type == "dynamic") {
    docker.createContainer({
      Image: 'res/express_myapp',
      Env: [
        'EXISTING_NODE=' + ip.address()
      ]
    }).then(function(container) {
      container.start();
      res.send({});
    });
  }
});

app.listen(3000, function() {
    console.log('Listening on the port 3000');
});
