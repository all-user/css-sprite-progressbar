Rx           = require 'rx'
makeStateful = (require '../util/stateful').makeStateful
SpriteTile   = require '../util/sprite-tile'
renderer     = require '../renderer/renderer'

###*
* HTMLの以下の部分と密結合しており、`ProgressbarModel`などのデータを元にプログレスバーを描画する
*
*     <div id='gauge-box'>
*         <div id="failed-msg">Oh! request failed...</div>
*         <div id='progress-bar'></div>
*         <div id='arrow-box'>
*         </div>
*     </div>
*
* @class ProgressbarView
* @uses Rx.Subject
* @uses Stateful
* @uses DHTMLSprite
* @constructor
* `ProgressbarView`のインスタンスを生成する
* @param {Number} globalFPS
* `Renderer`の様に画面の更新を実際に行う部分が達成しようとしているFPSを指定する<br>
* スプライトの更新や、移動、プログレスバーの増減などのアニメーションは、この値を元に相対的に時間係数を算出して描画する
###
class ProgressbarView

  ###*
  * @property {Boolean} [needsUpdate=no]
  * 進捗に未描画の更新がある場合に`true`になる
  * @private
  ###
  needsUpdate = no

  ###*
  * @property {Number} gFPS
  * `Renderer`の様に画面の更新を実際に行う部分が達成しようとしているFPSを指定する<br>
  * スプライトの更新や、移動、プログレスバーの増減などのアニメーションは、この値を元に相対的に時間係数を算出して描画する
  * @private
  ###
  gFPS = null

  constructor: (globalFPS) ->
    gFPS = globalFPS

    ###*
    * @property {Rx.Subject} eventStream
    * `ProgressbarView`で起きる全てのイベントが流れてくる`Rx.Subject`のインスタンス<br>
    * `.subscribe(observer)`で購読できる<br>
    * [RxJS Doc: Creating and subscribing to a simple sequence](https://github.com/Reactive-Extensions/RxJS/blob/master/doc/gettingstarted/creating.md#user-content-creating-and-subscribing-to-a-simple-sequence)
    *
    * Includes all the events of `ProgressbarView`<br>
    * this is instance of `Rx.Subject`<br>
    *
    *     progressbarView = new ProgressbarView();
    *
    *     progressbarView.eventStream.subscribe(function(e){
    *       console.log("event name: ", e.type);
    *       console.log("event data: ", e.data);
    *     });
    *
    * <h4>Event Format</h4>
    *
    *     {
    *         type: "name of event",
    *         data: "data from publisher"
    *     }
    *
    * <h4>Events</h4>
    * - **フェードイン・アウトの描画が終了した時**<br>
    *   `type: {String} "fadeend"`<br>
    *   `data: {null} null`
    * - **プログレスバーが非表示になった時**<br>
    *   `type: {String} "hide"`<br>
    *   `data: {null} null`
    ###
    @eventStream = new Rx.Subject()

    ###*
    * @property {Object} progressbar
    * プログレスバーのアニメーションに関するデータを保持するオブジェクト
    * @property {Object} progressbar.renderedProgress
    * 描画されたのプログレスバーの幅・割合・進捗度
    * @property {Object} progressbar.progress
    * プログレスバーがモデリングする実際の進捗度
    * @property {Object} progressbar.settings
    * @property {Object} progressbar.settings.targetFPS
    * @property {Object} [progressbar.settings.targetFPS.tile=20]
    * @property {Object} [progressbar.settings.targetFPS.slide=30]
    * @property {Object} [progressbar.settings.targetFPS.ratio=1.2]
    * @property {Number} [progressbar.settings.durationTime=1200]
    * バーが伸びるアニメーションの間隔をミリ秒で指定
    * @property {String} [progressbar.settings.easing="easeOutSine"]
    * バーが伸びるアニメーションのイージングを指定
    ###
    @progressbar =
      renderedProgress: 0
      progress        : 0
      countTime       : 0
      settings:
        durationTime: 1200
        easing      : 'easeOutExpo'
        targetFPS:
          tile : 20
          slide: 30
          ratio: 1.2
        resolutionFPS: null
    @display =
      opacity  : 0
      countTime: 0
      settings:
        durationTime : 500
        easing       : 'easeOutSine'
        resolutionFPS: null
    initialState =
      full : no
      model: {}
    makeStateful this, initialState


  elem:
    gaugeBox  : document.getElementById 'gauge-box'
    background: document.getElementById 'background-window'
    arrowBox  : document.getElementById 'arrow-box'
    progress  : document.getElementById 'progress-bar'
    failedMsg : document.getElementById 'failed-msg'

  speed:
    stop  : 0
    slow  : 1
    middle: 4
    fast  : 8

  easing :
    easeOutSine : (t, b, c, d) ->
      c * Math.sin(t/d * (Math.PI/2)) + b

    easeOutExpo : (t, b, c, d) ->
      if (t is d) then b+c else c * (-Math.pow(2, -10 * t/d) + 1) + b

  setGlobalFPS: (FPS) ->
    gFPS = FPS

  initProgressbar: ->
    @progressbar.countTime     = 0
    @progressbar.renderedProgress  = 0
    @progressbar.progress   = 0
    @elem.progress.style.width = '0%'
    @stateful.set 'full': no

  initDisplay: ->
    @display.countTime = 0

  notifyUpdate: ->
    needsUpdate = yes

  progressbarUpdate : ->

  makeProgressbarUpdate : ->
    throw new Error 'Must define globalFPS.' unless gFPS?
    model    = @stateful.get 'model'
    settings = @progressbar.settings
    duration = settings.durationTime / (1000 / gFPS)
    easing   = @easing[settings.easing]
    tiles    = [0, 100, 200, 300, 400, 500].map (pos) =>
      new SpriteTile
        x          : pos
        y          : 0
        width      : 100
        height     : 20
        imagesWidth: 400
        drawTarget : @elem.arrowBox
        images     : './images/arrow.png'
        indexLength: 28
    progressbarStyle = @elem.progress.style
    arrowboxStyle    = @elem.arrowBox.style
    tileCoeff  = settings.targetFPS.tile  / gFPS
    slideCoeff = settings.targetFPS.slide / gFPS
    ratioCoeff = settings.targetFPS.ratio / gFPS
    ratioUpdateTimer = 0
    slideCounter  = 0
    _renderRatio = =>
      @progressbar.countTime    = 0
      @progressbar.progress  = model.progress * 100
      @progressbar.renderedProgress = +progressbarStyle.width.replace('%', '')
      needsUpdate = no
    _throttleFrame =
      if settings.resolutionFPS == null
        (countTime) -> countTime
      else
        resolutionFramerate = gFPS / settings.resolutionFPS
        (countTime) -> countTime - (countTime % resolutionFramerate)
    @progressbarUpdate = (tCoeff) =>
      _tileCoeff = tCoeff * tileCoeff
      for tile in tiles
        tile.update(_tileCoeff)
      ratioUpdateTimer += tCoeff * ratioCoeff
      if ratioUpdateTimer > 1
        _renderRatio() if needsUpdate
        if model.canQuit and (+progressbarStyle.width.replace '%', '') >= 99.9
          @stateful.set 'full': yes
      if @progressbar.countTime <= duration
        @progressbar.countTime += tCoeff
        progressbarStyle.width = easing(
          _throttleFrame @progressbar.countTime
          @progressbar.renderedProgress
          @progressbar.progress - @progressbar.renderedProgress
          duration
        ) + '%'
      slideCounter += tCoeff * slideCoeff
      arrowboxStyle.left = "#{ slideCounter * @speed[model.flowSpeed] % 100 - 100 }px"
      ratioUpdateTimer %= 1

  fadingUpdate : ->

  makeFadingUpdate : ->
    model    = @stateful.get 'model'
    settings = @display.settings
    duration = settings.durationTime / (1000 / gFPS)
    easing   = @easing[settings.easing]
    gaugeboxStyle   = @elem.gaugeBox.style
    backgroundStyle = @elem.background.style
    _throttleFrame =
      if settings.resolutionFPS == null
        (countTime) -> countTime
      else
        resolutionFramerate = gFPS / settings.resolutionFPS
        (countTime) -> countTime - (countTime % resolutionFramerate)
    @makeFadingUpdate = =>
      type = model.fading
      currentOpacity = @display.opacity
      switch type
        when 'stop' then return
        when 'in'   then targetOpacity = 1
        when 'out'  then targetOpacity = 0
      @fadingUpdate = (tCoeff) =>
        @display.opacity = easing(
          _throttleFrame @display.countTime
          currentOpacity
          targetOpacity - currentOpacity
          duration)
        gaugeboxStyle.opacity   = @display.opacity * 0.5
        backgroundStyle.opacity = @display.opacity * 0.8
        if @display.countTime >= duration
          @display.opacity = targetOpacity
          @_displayChange('none') if model.fading is 'out'
          @eventStream.onNext
            'type': 'fadeend'
            'data': null
          @initDisplay()
          return
        @display.countTime += tCoeff
    @makeFadingUpdate()

  fadeInOut : (statusObj) ->
    @_displayChange('block') if statusObj.fading is 'in'
    @makeFadingUpdate()

  showFailedMsg : ->
    @elem.failedMsg.style.display = 'block'

  hideFailedMsg : ->
    @elem.failedMsg.style.display = 'none'

  _displayChange : (prop) ->
    @elem.gaugeBox.style.display   =
    @elem.background.style.display = prop
    if prop is 'none'
      @eventStream.onNext
        'type': 'hide'
        'data': null

module.exports = new ProgressbarView renderer.targetFPS
