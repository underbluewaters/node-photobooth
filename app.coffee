express = require 'express'
capture_photos = require './capture_photos'
convert = require './img_convert'
spawn = require('child_process').spawn
render_pdf = require('./generate_pdf.coffee').render_record
mongo = require 'mongodb'
mongode = require 'mongode'
serialport = require('serialport')
SerialPort = serialport.SerialPort
sessions_json = require './sessions_json'
register_photo_viewer = require('./transfer/photo_viewer').register

app = express.createServer()
io = require('socket.io').listen(app)
server = mongode.connect('photobooth', '127.0.0.1')
sessions = server.collection('sessions')

kill = spawn 'killall', [ 'PTPCamera'], {}


app.configure () ->
  # setup static file hosting
  app.set 'views', "#{__dirname}/views"
  app.set 'view engine', 'ejs'
  app.set 'view options', layout: false
  app.use app.router
  app.use express.static("#{__dirname}/transfer/public")
  app.use express.static("#{__dirname}/public")

# This may change from time to time. Not under my control
SERIAL_PORT = "/dev/tty.usbmodemfd131"
# To turn of printing for testing purposes
FAKE_PRINTING = true
PHOTOS = 5
INTERVAL = 4
# thumbnail dimensions
SMALL_W = 400
SMALL_H = 300
MEDIUM_W = 1600
MEDIUM_H = 1200

try
  sp = new SerialPort SERIAL_PORT, parser: serialport.parsers.readline("\r\n")
catch error
  console.log "SerialPort error, is the controller plugged in?"
  throw error  

app.get '/sessions.json', (req, res) ->
  res.contentType 'application/json'
  sessions_json.getJson (json) ->
    res.send json

register_photo_viewer app

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
      task = capture_photos PHOTOS, INTERVAL, "#{id}--%m-%y-%d_%H:%M:%S.jpg", "transfer/public/snaps"
      task.on 'capturing', (frame, total_frames) ->
        # let the client know when the photos are actually taken so that it 
        # can update the countdown
        socket.emit 'capturing', frame: frame
      task.on 'captured', (filename, frame, total_frames) ->
        handle = filename.split('.')[0]
        small = "transfer/public/snaps/#{handle}-small.jpg"
        medium = "transfer/public/snaps/#{handle}-medium.jpg"
        # create small and medium thumbnails
        orig = "transfer/public/snaps/#{filename}"
        convert orig, small, SMALL_W, SMALL_H, (output, w, h) ->
          convert orig, medium, MEDIUM_W, MEDIUM_H, (output, w, h) ->
            filename = "snaps/#{filename}"
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
    if data.share
      sessions.update({_id: new mongo.BSONPure.ObjectID(data._id)}, 
        {$set: {share: true}})
    render_pdf data._id, (filename) ->
      sessions.update({_id: new mongo.BSONPure.ObjectID(data._id)}, 
        {$set: {pdf: filename.split('public/')[1]}})
      if not FAKE_PRINTING
        spawn 'lp', ['-o landscape', filename]

  socket.on 'printerReady?', () ->
    if FAKE_PRINTING
      socket.emit 'printerReady', {}
    else
      e = spawn 'lpstat', ['-t'], {}
      e.stdout.on 'data', (data) ->
        if /now printing/.test(data) is false
          socket.emit 'printerReady', {}

  sp.on 'data', (data) ->
    socket.emit 'arduino-data', data
    
app.listen 3000