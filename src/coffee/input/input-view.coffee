Rx          = require 'rx'
makeStateful= (require '../util/stateful').makeStateful

dom = document.querySelector '#input-window'

###*
* HTMLの以下の部分と密結合しており、`input`要素や`button`要素で発生したイベントを通知する<br>
*
*     <div id="input-window">
*         <form>
*             <p>
*                 Freeword <input id="search-text" type="text" value="recent">
*                 Number of photos(1 - 500)<input id="per-page" type="number" value="200">
*                 Maximum of requests(1 - 500)<input id="max-req" type="number" value="5">
*             </p>
*         </form>
*         <button id="search-button">Search Flickr</button>
*         <button id="cancel-button">Cancel</button>
*     </div>
*
* @class InputView
* @uses Rx.Subject
* @uses Stateful
* @constructor
* `InputView`のインスタンスを生成する
###
class InputView
  constructor: ->
    ###*
    * @property {Rx.Observable} changeStream
    * `div#input-window`内の全ての`input`要素で発生した`change`イベントが流れてくる
    * @private
    ###
    @changeStream = Rx.Observable.fromEvent(
      dom.querySelectorAll 'input'
      'change')
      .map (e) -> e.target
    @clickStream = Rx.Observable.fromEvent dom, 'click'

    ###*
    * 状態の変更を通知する為の機能をまとめたオブジェクト<br>
    * 状態を変更、監視、取得するための方法は{@link Stateful}を参照<br>
    * デフォルトで`InputView.changeStream`を購読しており、`input`要素の内容に変更があると自動的に書き換わる<br>
    * 単方向のデータバインディング<br>
    * <h4>初期状態</h4>
    *
    *     {
    *         searchText: this.elem.searchText.value,
    *         perPage   : this.elem.perPage.value,
    *         maxReq    : this.elem.maxReq.value
    *     }
    *
    * <h4>各状態の意味</h4>
    * - **`searchText`**`: String`<br>
    *   Flikcr APIで写真を検索する際のキーワード
    * - **`perPage`**`: String`<br>
    *   1ページあたり何枚の写真を取得するか<br>
    *     このアプリケーションの場合は単純に取得する写真の枚数を表す
    * - **`maxReq`**`: String`<br>
    *   同時にダウンロードを開始する枚数を指定<br>
    *   例えばここで`1`を指定した場合、最初の一枚がダウンロードし終わるまで次の写真をダウンロードしない
    *
    * @member InputView
    * @property {Stateful} stateful
    * @mixin Stateful
    ###
    initialState =
      searchText: @elem.searchText.value
      perPage   : @elem.perPage.value
      maxReq    : @elem.maxReq.value
    makeStateful this, initialState
    toCamelCase = (s) ->
      s.replace(
        /(\w+)-(\w+)/
        (m, c1, c2) -> c1 + c2[0].toUpperCase() + c2.substr 1)
    @changeStream.subscribe(
      (e) =>
        data = {}
        data[toCamelCase e.id] = e.value
        @stateful.set data
      (e) -> console.log 'change subscribe error', e
      -> console.log 'change subscribe on complete')

  ###*
  * `div#input-window`内のinput要素とbutton要素の各`HTMLElement`への参照を保持するオブジェクト
  * @property {Object} elem
  * @property {HTMLInputElement} elem.searchText
  * @property {HTMLInputElement} elem.perPage
  * @property {HTMLInputElement} elem.maxReq
  * @property {HTMLButtonElement} elem.searchButton
  * @property {HTMLButtonElement} elem.cancelButton
  ###
  elem:
    searchText   : dom.querySelector '#search-text'
    perPage      : dom.querySelector '#per-page'
    maxReq       : dom.querySelector '#max-req'
    searchButton : dom.querySelector '#search-button'
    cancelButton : dom.querySelector '#cancel-button'


module.exports = new InputView
