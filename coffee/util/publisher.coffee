exports = this
exports.publisher =

  _subscribers :
    any : []

  on : (type = 'any', fn, context) ->
    fn = if typeof fn is 'function' then fn else context[fn]

    this._subscribers[type] = [] unless this._subscribers[type]?
    this._subscribers[type].push(fn : fn, context : context || this)

  remove : (type, fn, context) ->
    this.visitSubscribers('unsubseribe', type, fn, context)

  fire : (type, publication) ->
    this.visitSubscribers('publish', type, publication)

  visitSubscribers : (action, type = 'any', arg) ->
    pubtype = type
    subscribers = this._subscribers[pubtype]
    max = if subscribers? then subscribers.length else 0

    for i in [0...max]
      if action is 'publish'
        subscribers[i].fn.call(subscribers[i].context, arg)
      else
        if subscribers[i].fn is arg and subscribers[i].context is context
          subscribers.splice(i, 1)

    return

exports.makePublisher = (o) ->
  for own k of publisher
    o[k] = publisher[k] if typeof publisher[k] is 'function'

  o._subscribers = any : []
