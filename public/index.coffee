PHOTOS = 5
INTERVAL = 3
spinner_svg = '''
  <svg class="spinner" width="200" height="200" viewBox="0 0 300 300" xmlns="http://www.w3.org/2000/svg" version="1.1">
    <path d="M 150,0 a 150,150 0 0,1 106.066,256.066 l -35.355,-35.355 a -100,-100 0 0,0 -70.711,-170.711 z" fill="#E6E6E6"></path>
  </svg>
'''

watch = seconds: 0, photos: 0

$(document).ready () ->
  $('.button').each (i) ->
    button = $(this)
    setInterval () ->
      src = button.css 'background-image'
      if src.indexOf('depressed') is -1
        button.css 'background-image', src.replace(/\.png/, '-depressed.png')
      else
        button.css 'background-image', src.replace(/-depressed/, '')
    , 800 + (100 * i) # setting interval to be irregular among buttons
  
  headline = $($('#photographing h3')[1])
  setInterval () ->
    if watch.seconds is 0 and watch.photos is PHOTOS
      headline.text 'All Done'
    else if watch.seconds is 2 and watch.photos is 0
      headline.text 'Get Ready!'
    else if watch.photos is 1
      headline.text 'Looking Good!'
    else if watch.photos is 2
      headline.text ''
    else if watch.photos is PHOTOS - 1
      headline.text 'Almost done...'
  , 500

  $(document).keydown (e) ->
    switch e.keyCode
      when 65 # a
        console.log 'green'
        intro = $('#intro')
        if intro.is ':visible'
          intro.slideUp () ->
            enterPhotographingMode()
      when 83 #s
        console.log 'red'
      when 68 #d
        console.log 'black'
        review = $('#review')
        if review.is ':visible'
          enterStartView()
        
enterStartView = () ->
  $('.photo').remove()
  $('#review').hide()
  $('#intro').show()

enterPhotographingMode = () ->
  $(element).hide() for element in ['#intro', '#review', '#countdown']
  el = $('#photographing')
  el.fadeIn()
  photos_el = el.find('.photos')
  # Add photo divs to scene
  for num in [1..PHOTOS]
    angle = (Math.floor(Math.random() * 11) - 5)
    photos_el.append """
      <div id="photo#{num}" style="-webkit-transform: rotate(#{angle}deg);" class="photo">
        &nbsp;
        <div class="frame">
          &nbsp;
        </div>
      </div>
    """
  socket.emit 'capture-images', photos: PHOTOS, interval: INTERVAL
  # wait a bit for the PTP interface to boot up
  setTimeout () ->
    startCountdown 1
  , 500

startCountdown = (num) ->
  $("#photo"+(num - 1)).addClass('done')
  $('#countdown').remove()
  $('svg').remove()
  div = $("#photo#{num}")
  div.append '<span id="countdown"></span>'
  div.append spinner_svg
  seconds = 0
  countdown = $('#countdown')
  ref = setInterval () ->
    left = INTERVAL - seconds
    # clears the interval if the countdown is completed or if startCountdown
    # has been called on the next photo early
    clearInterval(ref) if left is 0 or watch.photos is not num - 1
    watch.seconds = left
    watch.photos = num - 1
    console.log(left)
    countdown.text(left)
    # make sure to scope these to the div in case photographs are taken in 
    # quick succession by a mistake of the camera PTP interface
    div.find('#countdown').animate {fontSize:'50px', marginTop: '60px', paddingLeft: '20px'}, 1000, () ->
        div.find('#countdown').css('font-size': '140px', marginTop: '0px', paddingLeft: '0px') unless left is 0
    seconds++
  , 1000 # one second
  
window.startCountdown = startCountdown

enterPhotoReview = () ->
  $('#intro, #countdown, #review').hide()
  $('#photographing').fadeOut () ->
    $('#review').show()
    $('.photos').clone().insertBefore '#review'
    $('#photographing .photos .photo').remove()

socket = io.connect('http://localhost');
socket.on 'connected', (data) ->
  console.log 'connected to socket.io service'
socket.on 'photo-ready', (data) ->
    console.log data.filename
