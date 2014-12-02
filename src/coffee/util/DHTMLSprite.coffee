DHTMLSprite = (options) ->
  { width, height, imagesWidth } = options
  element = document.createElement 'div'
  options.drawTarget.appendChild element
  eleStyle = element.style

  element.style.position = 'absolute'
  element.style.width = "#{ width }px"
  element.style.height = "#{ height }px"
  element.style.backgroundImage = "url(#{ options.images })"

  sprite =
    draw: (x, y) ->
      eleStyle.left = "#{ x }px"
      eleStyle.top = "#{ y }px"

    changeImage: (index) ->
      index *= width
      vOffset = -(index / imagesWidth | 0) * height
      hOffset = -index % imagesWidth
      eleStyle.backgroundPosition = "#{ hOffset }px #{ vOffset }px"

    show: ->
      eleStyle.display = 'block'

    hide: ->
      eleStyle.display = 'none'

    destroy: ->
      eleStyle.remove()


module.exports = DHTMLSprite
