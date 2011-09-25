mongo = require 'mongodb'
mongode = require 'mongode'
fs = require 'fs'

server = mongode.connect('photobooth', '127.0.0.1')
sessions = server.collection('sessions')

getJson = (callback) ->
  sessions.find({share: true}).limit(1000).toArray (err, docs) ->
    callback JSON.stringify(docs)
    
write = () ->
  getJson (json) ->
    fs.writeFile "#{__dirname}/transfer/public/sessions.json", json

module.exports = getJson: getJson, write: write  
