spawn = require('child_process').spawn

img_convert = (input, output, width, height, callback) ->
  spawn('convert', [
    input
    '-thumbnail'
    "#{width}x#{height}"
    output
  ]).on 'exit', () -> callback(output, width, height)
  return null
  
module.exports = img_convert