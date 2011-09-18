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

PHOTOS = 5
INTERVAL = 3

app.get '/', (req, res) ->
    res.render 'index', {NUM_PHOTOS: PHOTOS, INTERVAL: INTERVAL} 

io.sockets.on 'connection', (socket) ->
  # just for client-side logging
  socket.emit 'connected', {}
  # signal from the client to start taking photos
  socket.on 'capture-images', (data) ->
    task = capture_photos(PHOTOS, INTERVAL, "%m-%y-%d_%H:%M:%S.jpg", 'photos')
    task.on 'capturing', (frame, total_frames) ->
      # let the client know when the photos are actually taken so that it can
      # update the countdown
      socket.emit 'capturing', frame: frame
    task.on 'captured', (filename, frame, total_frames) ->
      # create small and medium thumbnails
      # gonna need flow control here to do two images at once?
      # once captured, let the client know it can display the photo
      socket.emit 'photo-ready',  filename: filename, 
                                  frame: frame, 
                                  small: small_filename, 
                                  large: large_filename

app.listen 3000