makePublisher = require '../util/publisher'

inputView =
  el :
    searchText   : document.getElementById('search-text')
    perPage      : document.getElementById('per-page')
    maxReq       : document.getElementById('max-req')
    searchButton : document.getElementById('search-button')
    canselButton : document.getElementById('cansel-button')
    photosView   : document.getElementById('photos-view')

  getOptions : ->
    options =
      text     : this.el.searchText.value
      per_page : this.el.perPage.value

    for own k of options
      delete options[k] if options[k] is ''

    options

  getMaxConcurrentRequest : ->
    maxReq = this.el.maxReq.value
    maxReq ? false

  handleClick : (e) ->
    this.fire('searchclick', e)

  handleCansel : (e) ->
    console.log('canselclick')
    this.fire('canselclick', e)

makePublisher(inputView)

inputView.el.searchButton.addEventListener('click', inputView.handleClick.bind(inputView))
inputView.el.canselButton.addEventListener('click', inputView.handleCansel.bind(inputView))

module.exports = inputView