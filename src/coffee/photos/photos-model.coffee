Rx = require 'rx'
makeStateful = (require '../util/stateful').makeStateful

###*
* 写真をロードして表示するクラス<br>
* 写真はURLの配列と任意の`Object`の配列として保持しており、<br>
* すべての写真のローディングの完了・未完了についても管理する<br>
* 実際の表示やローディングに関しては他のクラスが行う
* @class PhotosModel
* @uses Rx.Subject
* @uses stateful
* @constructor
* PhotosModelのインスタンスを生成する
###
class PhotosModel
  constructor: ->
    ###*
    * @property {Number} maxConcurrentRequest
    * @private
    * 同時に並列して写真をロードする数
    ###
    @maxConcurrentRequest = 0
    ###*
    * @property {Number} allRequestSize
    * @private
    * ロードする写真の総数
    ###
    @allRequestSize = 0
    ###*
    * @property {Number} loadedSize
    * @private
    * ロード済みの写真の数
    ###
    @loadedSize     = 0
    ###*
    * @property {String[]} photosURLArr
    * @private
    * 写真のURLの配列
    ###
    @photosURLArr   = []
    ###*
    * @property {String[]} unloadedURLArr
    * @private
    * ロード未完了の写真のURLの配列
    ###
    @unloadedURLArr = []
    ###*
    * @property {Object[]} photosArr
    * @private
    * 写真の配列<br>
    * 任意の`Object`の配列
    ###
    @photosArr      = []
    ###*
    * @property {Rx.Subject} eventStream
    * `PhotosModel`で起きる全てのイベントが流れてくる`Rx.Subject`のインスタンス<br>
    * `.subscribe(observer)`で購読できる<br>
    * [RxJS Doc: Creating and subscribing to a simple sequence](https://github.com/Reactive-Extensions/RxJS/blob/master/doc/gettingstarted/creating.md#user-content-creating-and-subscribing-to-a-simple-sequence)
    *
    * Includes all the events of `PhotosModel`<br>
    * this is instance of `Rx.Subject`<br>
    *
    *     photosModel = new PhotosModel();
    *
    *     photosModel.eventStream.subscribe(function(e){
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
    * - **全ての写真を消去した時**<br>
    *   `type: {String} "clear"`<br>
    *   `data: {null} null`
    * - **ロード未完了の写真のリストをクリアした時**<br>
    *   `type: {String} "clearunloaded"`<br>
    *   `data: {Number} ロード済みの数`
    * - **ロード済みの写真が一枚増えた時**<br>
    *   `type: {String} "loadedincreased"`<br>
    *   `data: {Number} ロード済みの数`
    * - **写真のロードを他のクラスに委譲する時**<br>
    *   `type: {String} "delegateloading"`<br>
    *   `data: {null} ロード委譲するURLの配列`
    *
    ###
    @eventStream    = new Rx.Subject()

    ###*
    * 状態の変更を通知する為の機能をまとめたオブジェクト<br>
    * 状態を変更、監視、取得するための方法は{@link Stateful}を参照<br>
    * <h4>初期状態</h4>
    *
    *     {
    *         'validated': false,
    *         'completed': false
    *     }
    *
    * <h4>各状態の意味</h4>
    * - **`validated`**`: Boolean`<br>
    *   `PhotosModel.validateProperties`が実行され、プロパティが正常な事が保証されている時`true`になる
    * - **`completed`**`: Boolean`<br>
    *   ロード待ちの写真が全てロードされた時に`true`になる
    *
    * @member PhotosModel
    * @property {Stateful} stateful
    * @mixin Stateful
    ###
    initialState =
      validated: no
      completed: no
    makeStateful this, initialState

  ###*
  * @method clear
  * 現在保持している全ての写真を破棄する<br>
  * 写真のURL配列、ロード完了、未完了などの情報も全て初期化される
  ###
  clear : ->
    @stateful.set
      validated: no
      completed: no
    @setProperties
      maxConcurrentRequest: 0
      allRequestSize      : 0
      loadedSize          : 0
      photosURLArr        : []
      unloadedURLArr      : []
      photosArr           : []
    @eventStream.onNext
      'type': 'clear'
      'data': null

  ###*
  * @method clearUnloaded
  * ロード未完了の写真の情報を破棄しロードする対象から外す<br>
  * 未完了の配列を破棄、総ロード数をロードが完了した数で上書きすることで今のところ実現<br>
  * 改善の余地あり？
  ###
  clearUnloaded : ->
    @setProperties
      unloadedURLArr : []
      allRequestSize : @loadedSize
    @eventStream.onNext
      'type': 'clearunloaded'
      'data': @loadedSize

  ###*
  * @method incrementLoadedSize
  * 写真のロードが一枚完了したことをこのクラスに通知する<br>
  * ロードが完了している数を表す`PhotosModel.loadedSize`を一つ増やす
  ###
  incrementLoadedSize : ->
    @loadedSize++
    @eventStream.onNext
      'type': 'loadedincreased'
      'data': @loadedSize
    @stateful.set 'completed', yes if @loadedSize >= @allRequestSize

  ###*
  * @method initPhotos
  * 写真のURLを受け取りロードを開始する<br>
  * @param {String[]} [urlArr] (required)
  * 写真のURLの配列
  ###
  initPhotos : (urlArr) ->
    @setProperties
      photosURLArr: urlArr
      allRequestSize: urlArr.length
    @validateProperties()
    @loadPhotos()

  ###*
  * @method loadPhotos
  * 写真をロードする<br>
  * その際`Photos.maxConcurrentRequest`で指定された数だけ並列して同時にロードする
  ###
  loadPhotos : ->
    @_load(@maxConcurrentRequest)

  ###*
  * @method loadNext
  * ロード未完了の写真から次の一枚をロードする
  ###
  loadNext : ->
    @_load(1)

  ###*
  * @method _load
  * `size`枚の写真をロードする<br>
  * 実際にロードをするのではなく、`delegateloading`イベントを`Photos.eventStream`に流す<br>
  * 他のクラスにそれをオブザーブさせ、ロードを委譲する
  * @param {Number} size (required)
  * ロードする写真の枚数
  * @private
  ###
  _load : (size) ->
    return if @unloadedURLArr.length is 0
    @eventStream.onNext
      'type': 'delegateloading'
      'data': @unloadedURLArr.splice(0, size)

  ###*
  * @method addPhoto
  * 写真を追加する<br>
  * `PhotosModel.photosArr`に`push`した後<br>
  * `PhotosModel.incrementLoadedSize`を呼び出す
  * @param {Object} img
  * 写真の実態となる任意の`Object`
  ###
  addPhoto : (img) ->
    @photosArr.push(img)
    @incrementLoadedSize()

  ###*
  * @method setProperties
  * キーと値のセットを渡しプロパティを設定する
  *
  * + `PhotosModel.maxConcurrentRequest`
  * + `PhotosModel.allRequestSize`
  *
  * @param {Object} props
  * 設定するキーと値のセット
  *
  *     {
  *         maxConcurrentRequest: value,
  *         allRequestSize      : value
  *     }
  *
  ###
  setProperties : (props) ->
    for own k, v of props
      this[k] = v if @hasOwnProperty(k)
    @stateful.set 'validated', no

  ###*
  * @method validateProperties
  * 以下のプロパティが正しい値になっているかをチェックする
  *
  * - `PhotosModel.maxConcurrentRequest`
  * - `PhotosModel.allRequestSize`
  * - `PhotosModel.unloadedURLArr`
  *
  ###
  validateProperties : ->
    try
      @maxConcurrentRequest *= 1
      @allRequestSize       *= 1
      throw new Error('maxConcurrentRequest is Nan') if isNaN(@maxConcurrentRequest)
      throw new Error('allRequestSize is Nan') if isNaN(@allRequestSize)
      @maxConcurrentRequest =
        if @maxConcurrentRequest > @allRequestSize
          @allRequestSize
        else
          if @maxConcurrentRequest > 0
            @maxConcurrentRequest
          else
            1
      @unloadedURLArr = @photosURLArr.slice()
      @stateful.set 'validated', yes
    catch e
      console.log('Error in photosModel.validateProperties')
      console.log("message -> #{ e.message }")
      console.log("stack -> #{ e.stack }")
      console.log("fileName -> #{ e.fileName || e.sourceURL }")
      console.log("line -> #{ e.line || e.lineNumber }")

  ###*
  * @method getNextPhoto
  * `PhotosModel.photosArr`から写真を一枚取り出す<br>
  * 引数に`received`を指定する必要がある
  * @param {Boolean[]} received
  * すでに受け取った写真を指定して重複を防ぐ<br>
  * 写真を取り出す際に除外する物を`true`に指定する<br>
  * `Boolean`の配列<br>
  ###
  getNextPhoto : (received) ->
    received ? console.log 'PhotosModel.getNextPhoto is received argument required'
    received ?= []
    return @_getPhotosArr(received, 1)

  ###*
  * @method _getPhotosArr
  * `PhotosModel.photosArr`から`length`枚の写真を取り出す<br>
  * 引数に`received`を指定する必要がある
  * @param {Boolean[]/Number} received
  * すでに受け取った写真を指定して重複を防ぐ<br>
  * 写真を取り出す際に除外する物を`true`に指定する<br>
  * `Boolean`の配列<br>
  * `Number`の引数をを渡した場合、そのインデックスの写真を取り出す
  * @param {Number} length
  * 取り出す写真の枚数
  * @private
  * @return {Object[]}
  * 取り出した写真の配列
  ###
  _getPhotosArr : (received, length) ->
    sent = []
    res  = []
    if received?
      if typeof received is 'number'
        res.push(@photosArr[received].cloneNode())
        sent = [received]
      else
        j = 0
        for i in [0...length]
          j++ while received[j]?
          break unless @photosArr[j]?
          res[i]  = @photosArr[j].cloneNode()
          sent[i] = j
    else
      res = @photosArr.slice(0, length)
      for v, i in res
        res[i]  = v.cloneNode() # photosArrの中のimgに対しての参照を消す
        sent[i] = i
    res.sent = sent
    res

module.exports = new PhotosModel
