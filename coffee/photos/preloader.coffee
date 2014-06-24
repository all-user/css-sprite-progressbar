exports = this

document.addEventListener('DOMContentLoaded', ->
  objfield = document.createElement('div')
  objfield.style.width = '0px'
  objfield.style.height = '0px'
  objfield.style.visibility = 'hidden'
  objfield.id = 'objfield'
  document.body.appendChild(objfield)

  exports.preloader =
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
      ( ->
        img = document.createElement('img')
        img.src = url
        this.fire('loaded', img)
      ).bind(this)

  makePublisher(preloader)

)
