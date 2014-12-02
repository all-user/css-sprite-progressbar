DHMTLSprite = require '../util/DHTMLSprite'

document.addEventListener 'DOMContentLoaded', ->
  console.log 'start'
  options =
    images: 'cogs.png'
    imagesWidth: 256
    width: 64
    height: 64
    drawTarget: document.querySelector '#draw-target'

  sprite1 = DHMTLSprite options
  sprite2 = DHMTLSprite options

  sprite2.changeImage 5
  sprite1.draw 64, 64
  sprite2.draw 352, 192
