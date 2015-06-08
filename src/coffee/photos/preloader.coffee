Rx = require 'rx'

###*
* 他のクラスに変わって画像をロードすることに特化したクラス<br>
* `<object>`要素の`data`属性に画像のURLを指定し、見えない状態でDOMに配置する事で画像をロードする
* @class
* @uses Rx.Subject
* @constructor
* `Preloader`のインスタンスを生成する
###
class Preloader
  constructor: ->
    ###*
    * @property {Rx.Subject} eventStream
    * `Preloader`で起きる全てのイベントが流れてくる`Rx.Subject`のインスタンス<br>
    * `.subscribe(observer)`で購読できる<br>
    * [RxJS Doc: Creating and subscribing to a simple sequence](https://github.com/Reactive-Extensions/RxJS/blob/master/doc/gettingstarted/creating.md#user-content-creating-and-subscribing-to-a-simple-sequence)
    *
    * Includes all the events of `Preloader`<br>
    * this is instance of `Rx.Subject`<br>
    *
    *     preloader = new Preloader();
    *
    *     preloader.eventStream.subscribe(function(e){
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
    * - **写真のロードが完了した時**<br>
    *   * `type: {String} "loaded"`
    *   * `data: {HTMLImageElement} ロードが完了した<img>要素`
    *
    ###
    @eventStream = new Rx.Subject()

  ###*
  * @property {HTMLDivElement} objectField
  * ロードをする際に`<object>`要素が配置される場所<br>
  * `body`の直下に位置し、`id`に`object-field`が設定される<br>
  * サイズを`0`、`visibility`を`hidden`にすることで見えないようになっている
  * @private
  ###
  objectField: do ->
    e = document.createElement('div')
    e.style.width      = '0px'
    e.style.height     = '0px'
    e.style.visibility = 'hidden'
    e.id = 'object-field'
    document.body.appendChild e
    e

  ###*
  * @method preload
  * 受け取ったURLの画像をロードする<br>
  * `<object>`要素を使ってデータをロードする<br>
  * ロードが完了した画像は`Preloader.eventStream`を購読して受け取る
  * @param {String[]} urlArr
  * ロードしたい画像のURLの配列
  ###
  preload : (urlArr) ->
    fragment = document.createDocumentFragment()
    body = document.body
    for v, i in urlArr
      obj = document.createElement 'object'
      obj.width  = 0
      obj.height = 0
      obj.data   = v
      obj.onload = @makeCreatePhoto(v)
      fragment.appendChild(obj)
    @objectField.appendChild(fragment)

  ###*
  * @method makeCreatePhoto
  * `Preloader.preload`によってロードされた画像のURLから`<img>(HTMLImageElement)`を生成する関数を生成する<br>
  * `Preloader.preload`の中で呼び出され、返り値の関数が`<object>`の`onload`にセットされる
  * @param {String} url
  * @return {Function}
  * @private
  ###
  makeCreatePhoto : (url) ->
    =>
      img = document.createElement 'img'
      img.src = url
      @eventStream.onNext
        'type': 'loaded'
        'data': img

module.exports = new Preloader
