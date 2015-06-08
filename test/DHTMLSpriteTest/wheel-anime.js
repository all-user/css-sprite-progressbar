var SpriteTile = require('./sprite-tile');

document.addEventListener('DOMContentLoaded', function() {
     var options = {
         width      : 50,
         height     : 50,
         imagesWidth: 200,
         images     : './images/wheel.png',
         drawTarget : document.getElementById('sprite-canvas'),
         x          : 150,
         y          : 80,
         indexLength: 8
     };
     var sprite = new SpriteTile(options);

     var timerID = setInterval(function() {
         sprite.update(1);
     }, 50);
});
