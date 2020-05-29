var Chance = require('chance');
var Express = require('express');

var chance = new Chance();
var app = new Express();

app.get('/', function(req, res) {
  console.log("Received a request !");
  res.send(generateTransactions());
});

app.listen(3000, function() {
  console.log('Listening on the port 3000');
});

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
