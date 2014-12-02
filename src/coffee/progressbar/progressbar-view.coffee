makePublisher = require '../util/publisher'
makeStateful = require '../util/stateful'
DHTMLSprite = require '../util/DHTMLSprite'

progressbarView =
  el :
    gaugeBox : document.getElementById('gauge-box')
    background : document.getElementById('background-window')
    arrowBox : document.getElementById('arrow-box')
    progress : document.getElementById('progress-bar')
    failedMsg : document.getElementById('failed-msg')


  _state :
    full : no
    model : {}

  speed :
    stop : 0
    slow : 1
    middle : 4
    fast : 8

  framerate : 16

  progressbar :
    passingWidth : 0
    recentWidth : 0
    countTime : 0
    settings :
      durationTime : 1500
      easing : 'easeOutExpo'

  display :
    opacity : 0
    countTime : 0
    settings :
      durationTime : 200
      easing : 'easeOutSine'

  easing :
    easeOutSine : (t, b, c, d) ->
      c * Math.sin(t/d * (Math.PI/2)) + b

    easeOutExpo : (t, b, c, d) ->
      if (t is d) then b+c else c * (-Math.pow(2, -10 * t/d) + 1) + b

  initProgressbar : ->
    this.progressbar.countTime = 0
    this.progressbar.passingWidth = 0
    this.progressbar.recentWidth = 0
    this.el.progress.style.width = '0%'
    this.changeState(full : no)

  initDisplay : ->
    this.display.countTime = 0


  spriteTile : (options) ->
    { x, y } = options
    index = 0
    sprite = DHTMLSprite(options)
    sprite.draw(x, y)

    sprite.update = () ->
      index++
      index %= 28
      sprite.changeImage index

    sprite


  progressbarUpdate : ->

  makeProgressbarUpdate : ->
    model = this._state.model
    framerate = this.framerate
    progressbar = this.progressbar
    settings = progressbar.settings
    duration = settings.durationTime / framerate | 0
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
    frame = 0

    _renderRatio = =>
      progressbar.countTime = 0
      progressbar.recentWidth = model.progress * 100
      progressbar.passingWidth = +progressbarStyle.width.replace('%', '')
      this.fire('ratiorendered', null)

    this.progressbarUpdate = =>
      # debug code start ->
      ltWatch progressbar
      # <- debug code end
      if ++frame % 2 is 0
        for tile in tiles
          tile.update()

      if frame % 50 is 0
        _renderRatio() if model.canRenderRatio
        this.changeState(full : yes) if model.canQuit and (+progressbarStyle.width.replace '%', '') >= 100

      if progressbar.countTime <= duration
        progressbarStyle.width = easing(
          progressbar.countTime++
          progressbar.passingWidth
          progressbar.recentWidth - progressbar.passingWidth
          duration
        ) + '%'
      frame %= 100
      arrowboxStyle.left = "#{ frame * this.speed[model.flowSpeed] % 100 - 100 }px"

  fadingUpdate : ->

  makeFadingUpdate : ->
    model = this._state.model
    framerate = this.framerate
    display = this.display
    settings = display.settings
    duration = settings.durationTime / framerate | 0
    easing = this.easing[settings.easing]
    gaugeboxStyle = this.el.gaugeBox.style
    backgroundStyle = this.el.background.style
    frame = 0

    this.makeFadingUpdate = =>
      type = model.fading
      currentOpacity = display.opacity

      switch type
        when 'stop' then return
        when 'in' then targetOpacity = 1
        when 'out' then targetOpacity = 0

      this.fadingUpdate = =>
        display.opacity = easing(
          display.countTime
          currentOpacity
          targetOpacity - currentOpacity
          duration
        )

        gaugeboxStyle.opacity = display.opacity * 0.5
        backgroundStyle.opacity = display.opacity * 0.8

        if display.countTime >= duration
          display.opacity = targetOpacity
          this._displayChange('none') if model.fading is 'out'
          this.fire('fadeend')
          this.initDisplay()
          return

        display.countTime++

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


makePublisher(progressbarView)
makeStateful(progressbarView)

module.exports = progressbarView
