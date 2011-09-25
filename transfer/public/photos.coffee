image = (img, size) ->
  return "/#{img[size]}"

pdf = (session) ->
  return "/#{session.pdf}"

content = $('#content')
$(document).ready ->
  content.html('')
  id = 0
  $.getJSON '/sessions.json', (data, textStatus) ->
    for session in data
      id++
      lis = ""
      for img in session.images
        lis = lis + """
        <li><a class="photo_link" rel="gallery_#{id}" href="#{image(img, 'medium')}">photo</a></li>
        """
      photoEl = $("""
      <div id="photo_#{id}" class="photo">
        <img src="#{image(session.images[0], 'small')}">
        <p><a class="slideshow" href="javascript:return false;">slideshow</a> | <a target="_blank" href="#{pdf(session)}">download printout</a></p>
        <ul class="photos" style="display:none;">
          #{lis}
        </ul>
      </div>
      """)
      content.append photoEl
      $("#photo_#{id} a.photo_link").colorbox({width:'80%'})
      $("#photo_#{id} a.slideshow").click () ->
        $($(this).parent().parent().find('.photo_link')[0]).click()
