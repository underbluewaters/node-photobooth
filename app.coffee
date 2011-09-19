express = require 'express'
capture_photos = require './capture_photos'
convert = require './img_convert'
spawn = require('child_process').spawn
render_pdf = require('./generate_pdf.coffee').render_record
mongo = require 'mongodb'
mongode = require 'mongode'

app = express.createServer()
io = require('socket.io').listen(app)
server = mongode.connect('photobooth', '127.0.0.1')
sessions = server.collection('sessions')

kill = spawn 'killall', [ 'PTPCamera'], {}


app.configure () ->
  # setup static file hosting
  app.use express.static("#{__dirname}/public")
  app.set 'views', "#{__dirname}/views"
  app.set 'view engine', 'ejs'
  app.set 'view options', layout: false

PHOTOS = 5
INTERVAL = 4
# thumbnail dimensions
SMALL_W = 400
SMALL_H = 300
MEDIUM_W = 1600
MEDIUM_H = 1200

app.get '/', (req, res) ->
    res.render 'index', NUM_PHOTOS: PHOTOS, INTERVAL: INTERVAL

io.sockets.on 'connection', (socket) ->
  # just for client-side logging
  socket.emit 'connected', {}
  # signal from the client to start taking photos
  socket.on 'capture-images', (data) ->
    # create a mongodb objectid
    id = new mongo.BSONPure.ObjectID()
    record = _id: id, images: []
    setTimeout () ->
      task = capture_photos PHOTOS, INTERVAL, "#{id}--%m-%y-%d_%H:%M:%S.jpg", "public/photos"
      task.on 'capturing', (frame, total_frames) ->
        # let the client know when the photos are actually taken so that it 
        # can update the countdown
        socket.emit 'capturing', frame: frame
      task.on 'captured', (filename, frame, total_frames) ->
        handle = filename.split('.')[0]
        small = "public/photos/#{handle}-small.jpg"
        medium = "public/photos/#{handle}-medium.jpg"
        # create small and medium thumbnails
        orig = "public/photos/#{filename}"
        convert orig, small, SMALL_W, SMALL_H, (output, w, h) ->
          convert orig, medium, MEDIUM_W, MEDIUM_H, (output, w, h) ->
            filename = "photos/#{filename}"
            small = small.split('public/')[1]
            medium = medium.split('public/')[1]
            record.images.push original: filename, small: small, medium: medium
            # once captured, let the client know it can display the photo
            socket.emit 'photo-ready', {
              frame: frame, 
              original: filename, 
              small: small, 
              medium: medium
            }
            if frame is PHOTOS
              sessions.insert record
              socket.emit 'photos-done', record
    , INTERVAL * 1000

  socket.on 'print', (data) ->
    render_pdf data._id, (filename) ->
      spawn 'lp', ['-o landscape', filename]
  
  socket.on 'printerReady?', () ->
    e = spawn 'lpstat', ['-t'], {}
    e.stdout.on 'data', (data) ->
      if /now printing/.test(data) is false
        socket.emit 'printerReady', {}
      
    
app.listen 3000