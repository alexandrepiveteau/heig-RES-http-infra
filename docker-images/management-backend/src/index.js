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
    docker.listContainers({all: true}, function(err, containers) {
        containers.forEach(function (containerInfo) {
            console.log("Container info id: " + containerInfo.Id);
        });
        console.log('ALL: ' + containers.length);
    });
    res.send({});
});

app.listen(3000, function() {
    console.log('Listening on the port 3000');
});
