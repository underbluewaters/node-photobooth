EventEmitter = require('events').EventEmitter
spawn = require('child_process').spawn

# RegExp matching various states of the capture process sent to stdout
saving = /Saving file as ([^.jpg]+)/g
capturing = /Capturing frame/g

capture_photos = (frames=5, interval=4, filename="%m-%y-%d_%H:%M:%S.jpg", cwd='photos') ->
  # keep track of number of captured frames...
  captured = 0
  # and their filenames
  filenames = []
  
  capture = spawn('gphoto2', [
    '--capture-image-and-download'
    "--frames=#{frames}"
    "--interval=#{interval}"
    "--filename=#{filename}"
    ], {cwd: cwd});
  

  # return events 'capturing', 'captured', and 'done'
  emitter = new EventEmitter()

  capture.stdout.on 'data', (data) ->
    # fire capturing event when photo is actually taken
    emitter.emit('capturing', captured + 1, frames) if capturing.exec(data.toString())
    # check if saving, and if so grab filename
    match = saving.exec(data.toString())
    if match
      file = "#{match[1]}.jpg"
      filenames.push file
      captured++
      # fire event when the photo is ready
      emitter.emit('captured', file, captured, frames)
      # check if final event should fire
      emitter.emit('done', filenames) if captured is frames

  return emitter

# Usage:
# capture_photos(2).on 'captured', (filename, captured, frames) ->
#   console.log "captured #{captured}/#{frames} frames: #{filename}"
  
module.exports = capture_photos