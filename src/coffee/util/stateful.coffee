Rx = require 'rx'
makePublisher = require './publisher'

stateful =
  _state : {}

  stream: null

  set : (prop, value) ->
    if typeof prop is 'object'
      this._changeState(prop, no)
    else if typeof prop is 'string'
      obj = {}
      obj[prop] = value
      this._changeState(obj, no)
    else
      throw new Error 'type error at arguments'

  get: (prop) ->
    this._state[prop]

  setOnlyUndefinedProp: (statusObj) ->
    this._changeState(statusObj, yes)

  _changeState : (statusObj, onlyUndefined) ->
    state = this._state
    changed = no
    for type, status of statusObj
      changeOwnProp = state.hasOwnProperty(type) and state[type] isnt status
      onlyUndefinedProp = not state.hasOwnProperty(type) and onlyUndefined
      if changeOwnProp or onlyUndefinedProp
        changed = yes
        state[type] = status
        newStatus = {}
        newStatus[type] = status
    this.stream.onNext state if changed

makeStateful = (o, initState) ->
  o.stateful ?= {}
  o.stateful._state = initState ? {}
  for own i, v of stateful
    o.stateful[i] = v if typeof v is 'function'
  o.stateful.stream = new Rx.Subject()
  makePublisher o.stateful

module.exports = makeStateful
