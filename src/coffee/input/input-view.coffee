Rx = require 'rx'
makeStateful= require '../util/stateful'

dom = document.querySelector '#input-window'
elem =
  searchText   : dom.querySelector '#search-text'
  perPage      : dom.querySelector '#per-page'
  maxReq       : dom.querySelector '#max-req'
  searchButton : dom.querySelector '#search-button'
  canselButton : dom.querySelector '#cansel-button'

initialState =
  searchText: ''
  perPage   : ''
  maxReq    : ''


inputView =

  elem: elem

  changeStream: Rx.Observable.fromEvent(
    dom.querySelectorAll 'input'
    'change')
    .map (e) -> e.target

  clickStream: Rx.Observable.fromEvent dom, 'click'

  getMaxConcurrentRequest : ->
    maxReq = this.elem.maxReq.value
    maxReq ? false


toCamelCase = (s)
  s.replace(
    /(\w+)-(\w+)/,
    (m, c1, c2) ->
      c1 + c2[0].toUpperCase() + c2.substr 1)

inputView.changeStream.subscribe(
  (e) ->
    data = {}
    data[toCamelCase e.id] = e.value
    inputView.stateful.set data
  (e) -> console.log 'change subscribe error', e
  -> console.log 'change subscribe on complete')


makeStateful inputView, initialState
inputView.stateful.set
  searchText: inputView.elem.searchText.value
  perPage   : inputView.elem.perPage.value
  maxReq    : inputView.elem.maxReq.value

module.exports = inputView
