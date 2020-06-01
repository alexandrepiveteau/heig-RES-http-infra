var Express = require('express');

var app = new Express();

app.get('/', function(req, res) {
  console.log("Received a request !");
  res.send({});
});

app.listen(3000, function() {
  console.log('Listening on the port 3000');
});
