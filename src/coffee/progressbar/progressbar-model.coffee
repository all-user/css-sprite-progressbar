Rx = require 'rx'
makeStateful = (require '../util/stateful').makeStateful

###*
* プログレスバーの状態を管理するクラス
* @class ProgressbarModel
* @uses Rx.Subject
* @uses Stateful
* @constructor
* ProgressbarModelのインスタンスを生成する
###
class ProgressbarModel
  constructor: ->
    ###*
    * @property {Rx.Subject} eventStream
    * `ProgressbarModel`で起きる全てのイベントが流れてくる`Rx.Subject`のインスタンス<br>
    * `.subscribe(observer)`で購読できる<br>
    * [RxJS Doc: Creating and subscribing to a simple sequence](https://github.com/Reactive-Extensions/RxJS/blob/master/doc/gettingstarted/creating.md#user-content-creating-and-subscribing-to-a-simple-sequence)
    *
    * Includes all the events of `ProgressbarModel`<br>
    * this is instance of `Rx.Subject`<br>
    *
    *     progressbarModel = new ProgressbarModel();
    *
    *     progressbarModel.eventStream.subscribe(function(e){
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
    * - **プログレスバーのアニメーションがスタートした時**<br>
    *   * `type: {String} "run"`
    *   * `data: {null} null`
    * - **プログレスバーのアニメーションが終了した時**<br>
    *   * `type: {String} "stop"`
    *   * `data: {null} null`
    * - **プログレスバーの状態がクリアされた時**<br>
    *   * `type: {String} "clear"`
    *   * `data: {null} null`
    *
    ###
    @eventStream = new Rx.Subject()

    ###*
    * 状態の変更を通知する為の機能をまとめたオブジェクト<br>
    * 状態を変更、監視、取得するための方法は{@link Stateful}を参照<br>
    * <h4>初期状態</h4>
    *
    *     {
    *         'fading'        : 'stop',
    *         'flowSpeed'     : 'slow',
    *         'denominator'   : 0,
    *         'numerator'     : 0,
    *         'progress'      : 0,
    *         'failed'        : false,
    *         'canQuit'       : false
    *     }
    *
    * <h4>各状態の意味</h4>
    * - **`fading`**`: String`<br>
    *   プログレスバーのフェードイン・アウトの状態を表す
    *     - `'stop'`<br>
    *       フェードイン・アウトしていない状態、何も変化していない状態
    *     - `'in'`<br>
    *       フェードインしている状態
    *     - `'out'`<br>
    *       フェードアウトしている状態
    * - **`flowSpeed`**`: String`<br>
    *   プログレスバーの横に流れるアニメーションのスピードを表す<br>
    *   プログレスバーのアニメーション中の何らかの変化量を表すのに使う
    *     - `'stop'`<br>
    *       停止している、流れない
    *     - `'slow'`<br>
    *       遅い、ゆっくり流れる
    *     - `'middle'`<br>
    *       普通、中くらいの速さで流れる
    *     - `'fast'`<br>
    *       速い、すばやく流れる
    * - **`denominator`**`: Number`<br>
    *   プログレスバーの進捗を計算する上での分母<br>
    *   進捗の、ゴール・目標値を指す数値
    * - **`numerator`**`: Number`<br>
    *   プログレスバーの進捗を計算する上での分子<br>
    *   タスク全体の内、完了したものを指す数値
    * - **`progress`**`: Number`<br>
    *   プログレスバーの進捗の割合を`0`〜`1`の間の数値で表す<br>
    *   `0`は全てのタスクが未完了、`1`は全てのタスクが完了したことを表す<br>
    *   `denominator`、`numerator`の値から自動的に計算される
    * - **`failed`**`: Boolean`<br>
    *   何らかの理由でエラーが起きている時に`true`になる
    * - **`canQuit`**`: Boolean`<br>
    *   全てのタスクが完了した時など、終了できる状態になった時`true`になる<br>
    *   `progress`が`1`になっていてもAPIのレスポンスを待っていて終了したくない場合などは`false`に設定する
    *
    * @member ProgressbarModel
    * @property {Stateful} stateful
    * @mixin Stateful
    ###
    initialState =
      fading        : 'stop'
      flowSpeed     : 'slow'
      denominator   : 0
      numerator     : 0
      progress      : 0
      failed        : no
      canQuit       : no
    makeStateful this, initialState

  ###*
  * @property {String[]} speed
  * `ProgressbarModel.stateful._state.speed`の取り得る値と、その順序を定義する配列<br>
  * @static
  * @private
  ###
  speed: [ 'stop', 'slow', 'middle', 'fast' ]

  ###*
  * @method run
  * プログレスバーの描画を開始したことを通知する<br>
  * 実際には`ProgressbarModel.eventStream`に`run`イベントを流すだけなので<br>
  * プレゼンテーション側で`run`を購読する必要がある
  ###
  run: ->
    @eventStream.onNext
      'type': 'run'
      'data': null

  ###*
  * @method stop
  * プログレスバーの描画を終了したことを通知する<br>
  * 実際には`ProgressbarModel.eventStream`に`stop`イベントを流すだけなので<br>
  * プレゼンテーション側で`stop`を購読する必要がある
  ###
  stop: ->
    @eventStream.onNext
      'type': 'stop'
      'data': null

  ###*
  * @method clear
  * プログレスバーの進捗の情報を破棄する<br>
  ###
  clear: ->
    @stateful.set
      denominator   : 0
      numerator     : 0
      progress      : 0
      canQuit       : no
    @eventStream.onNext
      'type': 'clear'
      'data': null

  ###*
  * @method fadeIn
  * プログレスバーをフェードイン・表示させる<br>
  * 実際には`stateful`の`fading`を`'in'`にセットするだけなので<br>
  * プレゼンテーション側で`fading`を購読する必要がある
  ###
  fadeIn: ->
    @stateful.set 'fading', 'in'

  ###*
  * @method fadeOut
  * プログレスバーをフェードアウト・非表示にする<br>
  * 実際には`stateful`の`fading`を`'out'`にセットするだけなので<br>
  * プレゼンテーション側で`fading`を購読する必要がある
  ###
  fadeOut: ->
    @stateful.set 'fading', 'out'

  ###*
  * @method fadeStop
  * プログレスバーのフェードイン・アウトを終了する<br>
  * 実際には`stateful`の`fading`を`'stop'`にセットするだけなので<br>
  * プレゼンテーション側で`fading`を購読する必要がある
  ###
  fadeStop: ->
    @stateful.set 'fading', 'stop'

  ###*
  * @method failed
  * エラーを表示させる<br>
  * 実際には`stateful`の`failed`を`true`にセットするだけなので<br>
  * プレゼンテーション側で`failed`を購読する必要がある
  ###
  failed: ->
    @stateful.set 'failed', yes

  ###*
  * @method resque
  * エラーから復帰させる<br>
  * 実際には`stateful`の`failed`を`false`にセットするだけなので<br>
  * プレゼンテーション側で`failed`を購読する必要がある
  ###
  resque: ->
    @stateful.set 'failed', no

  ###*
  * @method setFlowSpeed
  * プログレスバーの横に流れるアニメーションのスピードを変更する<br>
  * プログレスバーのアニメーション中の何らかの変化量を変更する
  * @param {String} speed
  * - `'stop'`<br>
  *   停止している、流れない
  * - `'slow'`<br>
  *   遅い、ゆっくり流れる
  * - `'middle'`<br>
  *   普通、中くらいの速さで流れる
  * - `'fast'`<br>
  *   速い、すばやく流れる
  ###
  setFlowSpeed: (speed) ->
    @stateful.set 'flowSpeed', speed unless @speed.indexOf(speed) == -1

  ###*
  * @method setDenominator
  * プログレスバーの進捗を計算する上での分母をセットする<br>
  * 進捗の、ゴール・目標値を指す数値をセットする
  * @param {Number} denomi
  * プログレスバーの進捗を計算する上での分母<br>
  * 進捗の、ゴール・目標値を指す数値
  ###
  setDenominator: (denomi) ->
    @_setProgress 'denominator', denomi

  ###*
  * @method
  * プログレスバーの進捗を計算する上での分子をセットする<br>
  * タスク全体の内、完了したものを指す数値をセットする
  * @param {Number} numer
  * プログレスバーの進捗を計算する上での分子<br>
  * タスク全体の内、完了したものを指す数値
  ###
  setNumerator: (numer) ->
    @_setProgress 'numerator', numer

  ###*
  * @method
  * `denominator`と`numerator`へのセッタ
  * @param {String} type
  * `denominator`か`numerator`を指定する
  * @param {Number} value
  * セットする値
  * @private
  ###
  _setProgress: (type, value) ->
    o = {}
    o[type] = value
    @stateful.set o
    @stateful.set
      progress      : @computeProgress()

  ###*
  * @method computeProgress
  * `denominator`、`numerator`から`progress`を算出する<br>
  * `denominator`、`numerator`が変更される時に自動的に呼び出される
  * @private
  * @return {Number}
  * プログレスバーの進捗の割合を`0`〜`1`の間で表した値<br>
  * `0`は全てのタスクが未完了、`1`は全てのタスクが完了したことを表す
  ###
  computeProgress: ->
    @stateful.get('numerator') / @stateful.get('denominator')


module.exports = new ProgressbarModel()
