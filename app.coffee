express = require 'express'
capture_photos = require './capture_photos'
convert = require './img_convert'

app = express.createServer()
io = require('socket.io').listen(app);

app.configure () ->
  # setup static file hosting
  app.use(express.static("#{__dirname}/public"))
  app.set 'views', "#{__dirname}/views"
  app.set 'view engine', 'ejs'
  app.set 'view options', layout: false

NUM_PHOTOS = 5
INTERVAL = 3

app.get '/', (req, res) ->
    res.render 'index', {NUM_PHOTOS: NUM_PHOTOS, INTERVAL: INTERVAL} 

io.sockets.on 'connection', (socket) ->
  # just for client-side logging
  socket.emit 'connected', {}
  socket.on 'capture-images', (data) ->
    console.log('capture-images')
    task = capture_photos(NUM_PHOTOS, INTERVAL, "%m-%y-%d_%H:%M:%S.jpg", 'photos')
    task.on 'capturing', (frame, total_frames) ->
      socket.emit 'capturing', frame: frame
    task.on 'captured', (filename, frame, total_frames) ->
      socket.emit 'photo-ready', filename: filename, frame: frame

app.listen 3000