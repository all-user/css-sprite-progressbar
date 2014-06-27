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
        try
          subscribers[i].fn.call(subscribers[i].context, arg)
        catch e
          try
            new Error("Error in #{ pubtype } : e -> #{ e }")
          catch
            console.log("message -> #{ e.message }")
            console.log("stack -> #{ e.stack }")
            console.log("fileName -> #{ e.fileName || e.sourceURL }")
            console.log("line -> #{ e.line || e.lineNumber }")
      else
        if subscribers[i].fn is arg and subscribers[i].context is context
          subscribers.splice(i, 1)

    return

exports.makePublisher = (o) ->
  for own k, v of publisher
    o[k] = v if typeof v is 'function'

  o._subscribers = any : []
