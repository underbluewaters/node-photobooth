spawn = require('child_process').spawn

img_convert = (input, output, width, height, callback) ->
  console.log 'convert', input, '-thumbnail', "#{width}x#{height}", output
  spawn('convert', [
    input
    '-thumbnail'
    "#{width}x#{height}"
    output
  ]).on 'exit', (code) -> console.log code; callback(output, width, height)
  return null
  
module.exports = img_convert