Rx = require 'rx'
makeStateful= require '../util/stateful'

window.dom = document.querySelector '#input-window'

window.inputView =
  elem :
    searchText   : dom.querySelector '#search-text'
    perPage      : dom.querySelector '#per-page'
    maxReq       : dom.querySelector '#max-req'
    searchButton : dom.querySelector '#search-button'
    canselButton : dom.querySelector '#cansel-button'

  _state :
    searchText   : ''
    perPage      : ''
    maxReq       : ''

  getOptions : ->
    options =
      text     : this.elem.searchText.value
      per_page : this.elem.perPage.value
    for own k of options
      delete options[k] if options[k] is ''
    options

  keyupStream: Rx.Observable.fromEvent dom, 'keyup'
    .map (e) -> e.target
    .filter (elem) ->
      elem.nodeName == 'INPUT'

  clickStream: Rx.Observable.fromEvent dom, 'click'

  getMaxConcurrentRequest : ->
    maxReq = this.elem.maxReq.value
    maxReq ? false

makeStateful inputView

toCamelCase = (s) ->
  s.replace(
    /(\w+)-(\w+)/,
    (m, c1, c2) ->
      c1 + c2[0].toUpperCase() + c2.substr 1)

inputView.keyupStream.subscribe(
  (e) ->
    data = {}
    data[toCamelCase e.id] = e.value
    inputView.changeState data,
  (e) ->
    console.log 'keyup subscribe error', e,
  ->
    console.log 'keyup subscribe on conplete')

inputView.changeState
  searchText : inputView.elem.searchText.value
  perPage : inputView.elem.perPage.value
  maxReq : inputView.elem.maxReq.value

module.exports = inputView
