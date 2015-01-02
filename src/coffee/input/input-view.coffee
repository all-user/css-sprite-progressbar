Rx = require 'rx'
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

  keyupStream: do ->
    el = document.querySelector '#input-window form'
    Rx.Observable.fromEvent el, 'keyup'
      .map (e) -> e.target
      .filter (el) ->
        el.nodeName == 'INPUT'

  getMaxConcurrentRequest : ->
    maxReq = this.el.maxReq.value
    maxReq ? false

  handleClick : (e) ->
    this.fire('searchclick', e)

  handleCansel : (e) ->
    this.fire('canselclick', e)

makePublisher inputView
makeStateful inputView

inputView.el.searchButton.addEventListener('click', inputView.handleClick.bind(inputView))
inputView.el.canselButton.addEventListener('click', inputView.handleCansel.bind(inputView))

inputView.keyupStream.subscribe(
  (e) ->
    toCamelCase = (s) ->
      s.replace(
        /(\w+)-(\w+)/,
        (m, c1, c2) ->
          c1 + c2[0].toUpperCase() + c2.substr 1)

    data = {}
    data[toCamelCase e.id] = e.value
    inputView.changeState data
    console.log inputView
  , (e) ->
    console.log 'keyup subscribe error', e
  , ->
    console.log 'keyup subscribe on conplete')


inputView.changeState
  searchText : inputView.el.searchText.value
  perPage : inputView.el.perPage.value
  maxReq : inputView.el.maxReq.value

module.exports = inputView
