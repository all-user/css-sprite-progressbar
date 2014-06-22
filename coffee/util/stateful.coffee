exports = this
exports.stateful =
  _state : {}

  changeState : (statusObj) ->
    this._changeState(statusObj, no)

  margeState : (statusObj) ->
    this._changeState(statusObj, yes)

  getState : (prop) ->
    this._state[prop]

  _changeState : (statusObj, marge) ->
    state = this._state
    changed = no

    for type, status of statusObj
      ownPropChanged = state.hasOwnProperty(type) and state[type] isnt status
      margeProp = not state.hasOwnProperty(type) and marge

      if ownPropChanged or margeProp
        changed = yes
        state[type] = status
        newStatus = {}
        newStatus[type] = status
        this.fire("#{ type.toLowerCase() }change", newStatus)

    this.fire("statechange", state) if changed

exports.makeStateful = (o) ->
  for own i, v of stateful
    o[i] = v if typeof v is 'function'

  o._state = o._state || {}
