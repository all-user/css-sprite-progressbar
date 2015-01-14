Rx = require 'rx'
makePublisher = require './publisher'

stateful =
  _state : {}

  changedStream: null

  changeState : (prop, value) ->
    if typeof prop is 'object'
      this._changeState(prop, no)
    else if typeof prop is 'string'
      obj = {}
      obj[prop] = value
      this._changeState(obj, no)
    else
      throw new Error 'type error at arguments'

  margeState : (statusObj) ->
    this._changeState(statusObj, yes)

  getState : (prop) ->
    this._state[prop]

  _changeState : (statusObj, marge) ->
    state = this._state
    changed = no
    for type, status of statusObj
      changeOwnProp = state.hasOwnProperty(type) and state[type] isnt status
      margeProp = not state.hasOwnProperty(type) and marge
      if changeOwnProp or margeProp
        changed = yes
        state[type] = status
        newStatus = {}
        newStatus[type] = status
    this.changedStream.onNext state if changed

makeStateful = (o) ->
  for own i, v of stateful
    o[i] = v if typeof v is 'function'
  o._state = o._state || {}
  o.changedStream = new Rx.Subject()
  makePublisher o

module.exports = makeStateful
