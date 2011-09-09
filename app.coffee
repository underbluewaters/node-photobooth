var express = require('express');

var app = express.createServer();
var io = require('socket.io').listen(app);

app.configure(function(){
  app.use(express.static(__dirname + '/public'));
  app.set('views', __dirname + '/views');
  app.set('view engine', 'ejs');
  app.set('view options', {
    layout: false
  });
});

app.get('/', function(req, res){
    res.render('index');
});

io.sockets.on('connection', function (socket) {
  socket.emit('connected', {});
  socket.on('capture-images', function (data) {
    console.log(data);
    var ref = setInterval(function(){
      if(data.photos === 0){
        clearTimeout(ref);
      }else{
        socket.emit('photo-ready', {filename: '/photos/123.jpg'});        
      }
      data.photos--;
    }, (data.interval + 1) * 1000);
  });
});

app.listen(3000);