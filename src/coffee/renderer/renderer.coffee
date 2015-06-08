makeStateful = (require '../util/stateful').makeStateful
TimeInfo = require '../util/time-info'

###*
* @class Renderer
* @uses Stateful
* @uses TimeInfo
* @constructor
* @param {Number} [targetFPS=60]
###
class Renderer
  constructor: (targetFPS) ->
    @updaters = []
    @targetFPS = targetFPS ? 60
    @framerate = 1000 / @targetFPS | 0
    @timerID = null
    initialState =
      running: no
      deleted: no
    makeStateful this, initialState

  ###*
  * @method addUpdater
  * @param {Function} updater
  ###
  addUpdater: (updater) ->
    if updater instanceof Array
      @updaters.concat(updater)
    else if typeof updater is 'function'
      @updaters.push(updater)

  ###*
  * @method deleteUpdater
  * @param {Function} updater
  ###
  deleteUpdater: (updater) ->
    @_visitUpdaters('delete', updater)

  ###*
  * @method _visitUpdaters
  * @param {String} action
  * @param {Function} fn
  * @private
  ###
  _visitUpdaters : (action, fn) ->
    if action is 'delete'
      for v, i in @updaters
        if v is fn
          @updaters[i] = null
          @stateful.set 'deleted': yes

  ###*
  * @method draw
  ###
  draw : ->
    return if @stateful.get 'running'
    @coeffTimer ?= new TimeInfo @targetFPS
    @stateful.set 'running': yes
    @timerID = setInterval =>
      info = @coeffTimer.getInfo()
      for v, i in @updaters
        v(info.coefficient)
      if @stateful.get 'deleted'
        i = 0
        until i is @updaters.length
          if @updaters[i]?
            i++
          else
            @updaters.splice i, 1
        @stateful.set 'deleted': no
    , @framerate

  ###*
  * @method pause
  ###
  pause : ->
    clearInterval(@timerID)
    @coeffTimer.pause()
    @stateful.set 'running': no


module.exports = new Renderer
