Rx = require 'rx'

objfield = document.createElement('div')
objfield.style.width = '0px'
objfield.style.height = '0px'
objfield.style.visibility = 'hidden'
objfield.id = 'objfield'
document.body.appendChild(objfield)

preloader =
  eventStream: new Rx.Subject()

  preload : (urlArr) ->
    fragment = document.createDocumentFragment()
    body = document.body
    for v, i in urlArr
      obj = document.createElement('object')
      obj.width = 0
      obj.height = 0
      obj.data = v
      obj.onload = this.makeCreatePhoto(v)
      fragment.appendChild(obj)
    objfield.appendChild(fragment)

  createPhoto : ->

  makeCreatePhoto : (url) ->
    =>
      img = document.createElement('img')
      img.src = url
      this.eventStream.onNext
        'type': 'loaded'
        'data': img

module.exports = preloader
