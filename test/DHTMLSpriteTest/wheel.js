var DHTMLSprite = require('./dhtml-sprite');

document.addEventListener('DOMContentLoaded', function() {
  var options = {
      width      : 50,
      height     : 50,
      imagesWidth: 200,
      images     : './images/wheel.png',
      drawTarget : document.getElementById('sprite-canvas')
  };
  var sprite = new DHTMLSprite(options);

  sprite.draw(150, 80);

  sprite.changeImage(5);
});
