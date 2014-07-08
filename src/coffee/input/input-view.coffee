makePublisher = require '../util/publisher'
makeStateful= require '../util/stateful'

inputView =
  el :
    searchText   : document.getElementById 'search-text'
    perPage      : document.getElementById 'per-page'
    maxReq       : document.getElementById 'max-req'
    searchButton : document.getElementById 'search-button'
    canselButton : document.getElementById 'cansel-button'
    photosView   : document.getElementById 'photos-view'
    inputWindow  : document.getElementById 'input-window'

  _state :
    searchText   : ''
    perPage      : ''
    maxReq       : ''

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
    this.fire('canselclick', e)

  handleInputKeyup : (e) ->
    return if e.target.tagName unless 'INPUT'
    id = e.target.id.replace /(\w+)-(\w+)/, (match, p1, p2) ->
      "#{ p1 }#{ p2[0].toUpperCase() }#{ p2.substr 1 }"
    oldValue = this._state[id]
    newValue = e.target.value
    this.changeState id, newValue if newValue isnt oldValue

makePublisher inputView
makeStateful inputView

inputView.el.searchButton.addEventListener('click', inputView.handleClick.bind(inputView))
inputView.el.canselButton.addEventListener('click', inputView.handleCansel.bind(inputView))
inputView.el.inputWindow.addEventListener('keyup', inputView.handleInputKeyup.bind(inputView))

inputView.changeState
  searchText : inputView.el.searchText.value
  perPage : inputView.el.perPage.value
  maxReq : inputView.el.maxReq.value

module.exports = inputView
