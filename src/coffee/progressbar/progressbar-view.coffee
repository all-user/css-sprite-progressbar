makePublisher = require '../util/publisher'
makeStateful = require '../util/stateful'
DHTMLSprite = require '../util/DHTMLSprite'

initialState =
  full : no
  model : {}

progressbarView =
  el :
    gaugeBox : document.getElementById('gauge-box')
    background : document.getElementById('background-window')
    arrowBox : document.getElementById('arrow-box')
    progress : document.getElementById('progress-bar')
    failedMsg : document.getElementById('failed-msg')

  speed :
    stop : 0
    slow : 1
    middle : 4
    fast : 8

  globalFPS: null

  progressbar:
    passingWidth: 0
    recentWidth: 0
    countTime: 0
    settings:
      durationTime: 1200
      easing: 'easeOutExpo'
      targetFPS:
        tile: 20
        slide: 30
        ratio: 1.2
      resolutionFPS: null

  display :
    opacity : 0
    countTime : 0
    settings :
      durationTime : 500
      easing : 'easeOutSine'
      resolutionFPS: null

  easing :
    easeOutSine : (t, b, c, d) ->
      c * Math.sin(t/d * (Math.PI/2)) + b

    easeOutExpo : (t, b, c, d) ->
      if (t is d) then b+c else c * (-Math.pow(2, -10 * t/d) + 1) + b

  setGlobalFPS: (FPS) ->
    this.globalFPS = FPS

  initProgressbar : ->
    this.progressbar.countTime = 0
    this.progressbar.passingWidth = 0
    this.progressbar.recentWidth = 0
    this.el.progress.style.width = '0%'
    this.stateful.set 'full': no

  initDisplay : ->
    this.display.countTime = 0

  spriteTile : (options) ->
    { x, y } = options
    index = 0
    sprite = DHTMLSprite(options)
    sprite.draw(x, y)

    sprite.update = (tCoeff) ->
      index += tCoeff
      index %= 28
      sprite.changeImage index | 0

    sprite


  progressbarUpdate : ->

  makeProgressbarUpdate : ->
    if this.globalFPS == null
      throw new Error 'Must define globalFPS.'

    model = this.stateful.get 'model'
    progressbar = this.progressbar
    settings = progressbar.settings
    duration = settings.durationTime / (1000 / this.globalFPS)
    easing = this.easing[settings.easing]
    tiles = [0, 100, 200, 300, 400, 500].map (pos) =>
      this.spriteTile
        x : pos
        y : 0
        width : 100
        height : 20
        imagesWidth : 400
        drawTarget : this.el.arrowBox
        images: './images/arrow.png'

    progressbarStyle = this.el.progress.style
    arrowboxStyle = this.el.arrowBox.style

    tileCoeff = settings.targetFPS.tile / this.globalFPS
    slideCoeff = settings.targetFPS.slide / this.globalFPS
    ratioCoeff = settings.targetFPS.ratio / this.globalFPS
    updateCounter = 0
    slideCounter = 0

    _renderRatio = =>
      progressbar.countTime = 0
      progressbar.recentWidth = model.progress * 100
      progressbar.passingWidth = +progressbarStyle.width.replace('%', '')
      this.fire('ratiorendered', null)

    _throttle =
      if settings.resolutionFPS == null
        (countTime) -> countTime
      else
        resolutionFramerate = this.globalFPS / settings.resolutionFPS
        (countTime) -> countTime - (countTime % resolutionFramerate)

    this.progressbarUpdate = (tCoeff) =>
      # debug code start ->
      # <- debug code end

      _tileCoeff = tCoeff * tileCoeff
      for tile in tiles
        tile.update(_tileCoeff)

      updateCounter += tCoeff * ratioCoeff
      if updateCounter > 1
        _renderRatio() if model.canRenderRatio
        if model.canQuit and (+progressbarStyle.width.replace '%', '') >= 99.9
          this.stateful.set 'full': yes

      if progressbar.countTime <= duration
        progressbar.countTime += tCoeff
        progressbarStyle.width = easing(
          _throttle progressbar.countTime
          progressbar.passingWidth
          progressbar.recentWidth - progressbar.passingWidth
          duration
        ) + '%'

      slideCounter += tCoeff * slideCoeff
      arrowboxStyle.left = "#{ slideCounter * this.speed[model.flowSpeed] % 100 - 100 }px"

      updateCounter %= 1

  fadingUpdate : ->

  makeFadingUpdate : ->
    model = this.stateful.get 'model'
    display = this.display
    settings = display.settings
    duration = settings.durationTime / (1000 / this.globalFPS)
    easing = this.easing[settings.easing]
    gaugeboxStyle = this.el.gaugeBox.style
    backgroundStyle = this.el.background.style
    _throttle =
      if settings.resolutionFPS == null
        (countTime) -> countTime
      else
        resolutionFramerate = this.globalFPS / settings.resolutionFPS
        (countTime) -> countTime - (countTime % resolutionFramerate)
    this.makeFadingUpdate = =>
      type = model.fading
      currentOpacity = display.opacity
      switch type
        when 'stop' then return
        when 'in' then targetOpacity = 1
        when 'out' then targetOpacity = 0
      this.fadingUpdate = (tCoeff) =>
        display.opacity = easing(
          _throttle display.countTime
          currentOpacity
          targetOpacity - currentOpacity
          duration)
        gaugeboxStyle.opacity = display.opacity * 0.5
        backgroundStyle.opacity = display.opacity * 0.8
        if display.countTime >= duration
          display.opacity = targetOpacity
          this._displayChange('none') if model.fading is 'out'
          this.fire('fadeend')
          this.initDisplay()
          return
        display.countTime += tCoeff
    this.makeFadingUpdate()

  fadeInOut : (statusObj) ->
    this._displayChange('block') if statusObj.fading is 'in'
    this.makeFadingUpdate()

  showFailedMsg : ->
    this.el.failedMsg.style.display = "block"

  hideFailedMsg : ->
    this.el.failedMsg.style.display = "none"

  _displayChange : (prop) ->
    this.el.gaugeBox.style.display =
    this.el.background.style.display = prop
    this.fire('hide', null) if prop is "none"


makePublisher progressbarView
makeStateful progressbarView, initialState

module.exports = progressbarView
