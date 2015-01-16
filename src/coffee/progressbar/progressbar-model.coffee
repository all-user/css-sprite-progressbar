makePublisher = require '../util/publisher'
makeStateful = require '../util/stateful'

initialState =
  hidden: yes
  fading: 'stop'
  failed: no
  flowSpeed: 'slow'
  denominator: 0
  numerator: 0
  progress: 0
  canRenderRatio: no
  canQuit: no


progressbarModel =
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
    this.stateful.set
      denominator: 0
      numerator: 0
      progress: 0
      canRenderRatio: yes
      canQuit: no
    this.fire('clear', null)

  fadeIn : ->
    this.stateful.set 'fading', 'in'

  fadeOut : ->
    this.stateful.set 'fading', 'out'

  fadeStop : ->
    this.stateful.set 'fading', 'stop'

  failed : ->
    this.stateful.set 'failed', yes

  resque : ->
    this.stateful.set 'failed', no

  setFlowSpeed : (speed) ->
    this.stateful.set 'flowSpeed', speed if this.speed.type.hasOwnProperty(speed)

  flowMoreFaster : ->
    currentSpeed = this.speed.type[this.stateful.get 'flowSpeed']
    this.setFlowSpeed(this.speed.array[currentSpeed + 1])

  flowMoreSlower : ->
    currentSpeed = this.speed.type[this.stateful.get 'flowSpeed']
    this.setFlowSpeed(this.speed.array[currentSpeed - 1])

  setDenominator : (denomi) ->
    this._setProgress('denominator', denomi)

  setNumerator : (numer) ->
    this._setProgress('numerator', numer)

  _setProgress : (type, value) ->
    o = {}
    o[type] = value
    this.stateful.set o
    this.stateful.set
      progress: this.computeProgress()
      canRenderRatio: yes

  computeProgress : (process) ->
    res = this.stateful.get('numerator') / this.stateful.get('denominator')
    res = Math[this.processType[process]](res) if this.processType.hasOwnProperty(process)
    res

makePublisher progressbarModel
makeStateful progressbarModel, initialState

module.exports = progressbarModel
