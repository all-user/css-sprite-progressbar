makePublisher = require '../util/publisher'
makeStateful = require '../util/stateful'

progressbarModel =
  _state :
    hidden : yes
    fading : 'stop'
    failed : no
    flowSpeed : 'slow'
    denominator : 0
    numerator : 0
    progress : 0
    canRenderRatio : no
    canQuit : no

  speed :
    type :
      stop : 0
      slow : 1
      middle : 2
      fast : 3
    array : [
      'stop'
      'slow'
      'middle'
      'fast'
    ]

  processType :
    ceil : 'ceil'
    floor : 'floor'
    round : 'round'

  run : ->
    this.fire('run', this)

  stop : ->
    this.fire('stop', this)

  clear : ->
    this.changeState(
      denominator : 0
      numerator : 0
      progress : 0
      canRenderRatio : yes
      canQuit : no
    )
    this.fire('clear', null)

  fadeIn : ->
    this.changeState(fading : 'in')

  fadeOut : ->
    this.changeState(fading : 'out')

  fadeStop : ->
    this.changeState(fading: 'stop')

  failed : ->
    this.changeState(failed: yes)

  resque : ->
    this.changeState(failed: no)

  setFlowSpeed : (speed) ->
    this.changeState(flowSpeed : speed) if this.speed.type.hasOwnProperty(speed)

  flowMoreFaster : ->
    currentSpeed = this.speed.type[this._state.flowSpeed]
    this.setFlowSpeed(this.speed.array[currentSpeed + 1])

  flowMoreSlower : ->
    currentSpeed = this.speed.type[this._state.flowSpeed]
    this.setFlowSpeed(this.speed.array[currentSpeed - 1])

  setDenominator : (denomi) ->
    this._setProgress('denominator', denomi)

  setNumerator : (numer) ->
    this._setProgress('numerator', numer)

  _setProgress : (type, value) ->
    o = {}
    o[type] = value
    this.changeState(o)
    this.changeState(
      progress : this.getProgress()
      canRenderRatio : yes
    )

  getProgress : (process) ->
    res = this._state.numerator / this._state.denominator
    Math[this.processType[process]](res) if this.processType.hasOwnProperty(process)
    res

makePublisher(progressbarModel)
makeStateful(progressbarModel)

module.exports = progressbarModel
