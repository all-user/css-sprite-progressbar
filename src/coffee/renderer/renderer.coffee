makePublisher = require '../util/publisher'
makeStateful = require '../util/stateful'
timeInfo = require '../util/timeInfo'

renderer =
  updaters : []
  framerate : 16
  targetFPS : 30
  timerID : null

  _state :
    running : no
    deleted : no

  addUpdater : (updater) ->
    if updater instanceof Array
      this.updaters.concat(updater)
    else if typeof updater is 'function'
      this.updaters.push(updater)

  deleteUpdater : (updater) ->
    this._visitUpdaters('delete', updater)

  _visitUpdaters : (action, fn) ->
    updaters = this.updaters

    if action is 'delete'
      for v, i in updaters
        if v is fn
          updaters[i] = null
          this.changeState(deleted : yes)

  draw : ->

  pause : ->
    clearInterval(this.timerID)
    this.changeState(running : no)

  makeDraw : ->
    updaters = this.updaters

    this.draw = =>
      return if this._state.running

      coeffTimer = timeInfo this.targetFPS

      this.changeState(running : yes)

      this.timerID = setInterval( =>
        info = coeffTimer.getInfo()
        for v, i in updaters
          try
            v(info.coefficient)
          catch e
            try
              new Error("Error in draw : e -> #{ e }")
            catch
              console.log("message -> #{ e.message }")
              console.log("stack -> #{ e.stack }")
              console.log("fileName -> #{ e.fileName || e.sourceURL }")
              console.log("line -> #{ e.line || e.lineNumber }")

        if this._state.deleted
          i = 0
          until i is updaters.length
            if updaters[i] is null
              updaters.splice(i, 1)
            else
              i++
          this.changeState(deleted : no)

      , this.framerate)

renderer.makeDraw()
makePublisher(renderer)
makeStateful(renderer)

module.exports = renderer
