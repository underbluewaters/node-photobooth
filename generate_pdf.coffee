PDFDocument = require 'pdfkit'
mongo = require 'mongodb'
mongode = require 'mongode'

server = mongode.connect('photobooth', '127.0.0.1')
sessions = server.collection('sessions')

generate_pdf = (take, filename, callback) ->
  doc = new PDFDocument
    size: [432, 288]
    info:
      Title: "Chad&Jen's Photo Booth Session"
      Author: "Chad and Jennifer Burt"

  doc.fontSize(18)
  doc.font('fonts/LaBelleAurore.ttf')
  doc.text('Chad & Jen Burt, October 1st 2011', 95, 98)
  doc.fontSize(12)
  doc.text('download these photos at http://chadandjen.net/photos', 92, 121)

  doc.image("public/#{take.images[0].original}", 0, 0, fit: [144, 96])
  doc.image("public/#{take.images[1].original}", 144, 0, fit: [144, 96])
  doc.image("public/#{take.images[2].original}", 288, 0, fit: [144, 96])

  doc.image("public/#{take.images[3].original}", 0, 144, fit: [216, 144])
  doc.image("public/#{take.images[4].original}", 216, 144, fit: [216, 144])
  
  doc.write filename, () ->
    callback(filename)
  
  return null

module.exports = {
  generate_pdf: generate_pdf,
  render_record: (idString, callback) ->
    id = new mongo.BSONPure.ObjectID(idString)
    sessions.findOne '_id': id, (err, record) ->
      generate_pdf(record, "public/pdf/#{record._id}.pdf", callback)
      
}

return false