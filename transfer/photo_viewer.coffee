express = require 'express'
ejs = require 'ejs'

register = (app) ->
  app.get '/photos', (req, res) ->
    res.render("#{__dirname}/views/photos.ejs", {})

module.exports = register: register