makeStateful = require '../util/stateful'
timeInfo = require '../util/timeInfo'

initialState =
  running : no
  deleted : no

renderer =
  updaters : []
  framerate : 16
  targetFPS : 60
  timerID : null

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
          this.stateful.set 'deleted': yes

  draw : ->

  pause : ->
    clearInterval(this.timerID)
    this.stateful.set 'running': no

  makeDraw : ->
    updaters = this.updaters
    this.draw = =>
      return if this.stateful.get 'running'
      coeffTimer = timeInfo this.targetFPS
      this.stateful.set 'running': yes
      this.timerID = setInterval( =>
        info = coeffTimer.getInfo()
        for v, i in updaters
          v(info.coefficient)
        if this.stateful.get 'deleted'
          i = 0
          until i is updaters.length
            if updaters[i]?
              i++
            else
              updaters.splice i, 1
          this.stateful.set 'deleted': no
      , this.framerate)

renderer.makeDraw()
makeStateful renderer, initialState

module.exports = renderer
