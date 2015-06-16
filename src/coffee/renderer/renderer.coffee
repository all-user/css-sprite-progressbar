xtend        = require 'xtend'
makeStateful = (require '../util/stateful').makeStateful
TimeInfo     = require '../util/time-info'
Clock        = require '../../../../Clock.js/lib/Clock'

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
    @targetFPS = targetFPS ? 60
    @timeInfo  = new TimeInfo @targetFPS
    transform = (ts, _) =>
      info = @timeInfo.getInfo ts
      info.coefficient
    opt = xtend(_clock_option, 'transform': transform)
    @clock     = new Clock [], opt
    initialState =
      running: no
      deleted: no
    makeStateful this, initialState

  ###*
  * @method addUpdater
  * @param { Function || [Function] } updater
  ###
  addUpdater: (updater) ->
    if updater instanceof Array
      @clock.on fn for fn in updater
    else if typeof updater is 'function'
      @clock.on updater

  ###*
  * @method deleteUpdater
  * @param {Function} updater
  ###
  deleteUpdater: (updater) ->
    @clock.off updater


  ###*
  * @method draw
  ###
  draw : ->
    if @clock.active
      unless @stateful.get 'running'
        @stateful.set 'running': yes
      return
    @clock.start()
    @stateful.set 'running': yes

  ###*
  * @method pause
  ###
  pause : ->
    @clock.stop()
    @timeInfo.pause()
    @stateful.set 'running': no


module.exports = Renderer
