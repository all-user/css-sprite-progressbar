makeStateful = (require '../util/stateful').makeStateful
TimeInfo = require '../util/time-info'
Clock = require '../../../../Clock.js/lib/Clock'

_clock_option =
  vsync: on

# config of testing
#   vsync: off
#   wait : 30
#   pulse: 4

###*
* @class Renderer
* @uses Stateful
* @uses TimeInfo
* @constructor
* @param {Number} [targetFPS=60]
###
class Renderer

  constructor: (targetFPS) ->
    @clock     = new Clock [], _clock_option
    @updaters  = []
    @targetFPS = targetFPS ? 60
    @framerate = 1000 / @targetFPS | 0
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
      pos = @updaters.indexOf fn
      if pos isnt -1 and @updaters[pos] is fn
        @updaters[pos] = null
        @stateful.set 'deleted': yes


  _enterFrame: (timestamp) =>
    info = @coeffTimer.getInfo timestamp
    for fn, _ in @updaters
      fn info.coefficient
    if @stateful.get 'deleted'
      i = 0; denseArray = []
      for fn, _ in @updaters
        denseArray.push fn if fn
      @updaters = denseArray
      @stateful.set 'deleted': no

  ###*
  * @method draw
  ###
  draw : ->
    return if @stateful.get 'running'
    @coeffTimer ?= new TimeInfo @targetFPS
    @stateful.set 'running': yes
    @clock.on @_enterFrame
    @clock.start()

  ###*
  * @method pause
  ###
  pause : ->
    @clock.stop()
    @clock.off @_enterFrame
    @coeffTimer.pause()
    @stateful.set 'running': no


module.exports = Renderer
