mongo = require 'mongodb'
mongode = require 'mongode'
fs = require 'fs'

server = mongode.connect('photobooth', '127.0.0.1')
sessions = server.collection('sessions')

module.exports = () ->
  sessions.find({share: {$ne: true}}).each (err, doc) ->
    if err
      throw err
    else if doc
      console.log doc
      for image in doc.images
        fs.unlink("#{__dirname}/public/#{image.original}")
        fs.unlink("#{__dirname}/public/#{image.small}")
        fs.unlink("#{__dirname}/public/#{image.medium}")
      console.log("unlinked #{doc._id} images")
      if doc.pdf?
        fs.unlink("#{__dirname}/public/#{doc.pdf}")
      console.log("unlinked #{doc._id} pdf")
      sessions.remove({_id: doc._id})