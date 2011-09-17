(function() {
  var INTERVAL, PHOTOS;
  PHOTOS = 5;
  INTERVAL = 3;
  $(document).ready(function() {
    return $('.button').each(function(i) {
      var button;
      button = $(this);
      return setInterval(function() {
        var src;
        src = button.css('background-image');
        if (src.indexOf('depressed' === -1)) {
          return button.css('background-image', src.replace(/\.png/, '-depressed.png'));
        } else {
          return button.css('background-image', src.replace(/-depressed/, ''));
        }
      }, 800 + (100 * i));
    });
  });
}).call(this);
