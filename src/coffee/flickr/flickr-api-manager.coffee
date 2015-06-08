Rx = require 'rx'
makeStateful = (require '../util/stateful').makeStateful

###*
* Flickr APIの応答によって呼び出される関数<br>
* 関数名は`jsonFlickrApi`に固定されている<br>
* このアプリケーションでは{@link FlickrAPIManager}によってFlickr APIの応答を監視するためだけに使用する<br>
*
* Flickr API Documentation:
*
* - [JSON Format](https://www.flickr.com/services/api/response.json.html)<br>
* - [flickr.photos.search](https://www.flickr.com/services/api/flickr.photos.search.htm)<br>
* - [Flickr API Explorer](https://www.flickr.com/services/api/explore/flickr.photos.search)
* @class jsonFlickrApi
* @private
* @uses Rx.Subject
* @param {Object} json
* <h4>JSON Response Format</h4>
*
*      jsonFlickrApi({
*          "photos": {
*              "page"   : 1,
*              "pages"  : "507461",
*              "perpage": 2,
*              "total"  : "1014922",
*              "photo"  : [
*                  {
*                      "id"      : "16351013591",
*                      "owner"   : "67146260@N02",
*                      "secret"  : "f3694336d4",
*                      "server"  : "8569",
*                      "farm"    : 9,
*                      "title"   : "Lake Emmanuel",
*                      "ispublic": 1,
*                      "isfriend": 0,
*                      "isfamily": 0
*                  },
*                  {
*                      "id"      : "16166953777",
*                      "owner"   : "16086466@N03",
*                      "secret"  : "f1de6a7bfd",
*                      "server"  : "8566",
*                      "farm"    : 9,
*                      "title"   : "Kings Canyon & Sequoia - 99",
*                      "ispublic": 1,
*                      "isfriend": 0,
*                      "isfamily": 0
*                  }
*              ]
*          },
*          "stat": "ok"
*      })
*
###
window.jsonFlickrApi = (json) ->
  jsonFlickrApi.eventStream.onNext
    'type': 'apiresponse'
    'data': json

###*
* @property {Rx.Subject} eventStream
* `jsonFlickrApi`で起きる全てのイベントが流れてくるRx.Subjectのインスタンス<br>
* `.subscribe(observer)`で購読できる<br>
* [RxJS Doc: Creating and subscribing to a simple sequence](https://github.com/Reactive-Extensions/RxJS/blob/master/doc/gettingstarted/creating.md#user-content-creating-and-subscribing-to-a-simple-sequence)
*
* Includes all the events of jsonFlickrApi<br>
* this is instance of Rx.Subject<br>
*
*     jsonFlickrApi.eventStream.subscribe(function(e){
*       console.log("event name: %s", e.type);
*       console.log("event data: %s", e.data);
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
* - **Flickr APIが応答した時**<br>
*   **when Flickr API responded**<br>
*   * `type: {String} "apiresponse"`
*   * `data: {Object} JSON Response from Flickr API`
*
###
jsonFlickrApi.eventStream = new Rx.Subject()
apiResponseStream = jsonFlickrApi.eventStream
  .filter (e) -> e.type is 'apiresponse'


###*
* Flickr APIとの通信全般を担当する<br>
* <https://www.flickr.com/services/api/response.json.html><br>
* <https://www.flickr.com/services/api/explore/flickr.photos.search><br>
* <https://www.flickr.com/services/api/flickr.photos.search.htm><br>
* @class FlickrAPIManager
* @uses Rx.Subject
* @uses Stateful
* @constructor
* `FlickrAPIManager`のインスタンスを生成する
###
class FlickrAPIManager
  constructor: ->
    ###*
    * @property {Rx.Subject} eventStream
    * `FlickrAPIManager`で起きる全てのイベントが流れてくる`Rx.Subject`のインスタンス<br>
    * `.subscribe(observer)`で購読できる<br>
    * [RxJS Doc: Creating and subscribing to a simple sequence](https://github.com/Reactive-Extensions/RxJS/blob/master/doc/gettingstarted/creating.md#user-content-creating-and-subscribing-to-a-simple-sequence)
    *
    * Includes all the events of `FlickrAPIManager`<br>
    * this is instance of `Rx.Subject`
    *
    *     flickrAPIManager = new FlickrAPIManager();
    *
    *     flickrAPIManager.eventStream.subscribe(function(e){
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
    * - **Flickr APIにリクエストを送信した時**<br>
    *   `type: {String} "sendrequest"`<br>
    *   `data: {null} null`
    * - **Flickr APIが応答した時**<br>
    *   `type: {String} "apiresponse"`<br>
    *   `data: {Object} JSON Response from Flickr API`
    * - **Flickr APIの返したデータからURLの配列を生成した時**<br>
    *   `type: {String} "urlready"`<br>
    *   `data: {Array} 写真のURL配列`
    * - **Flickr APIとの通信に失敗した時**<br>
    *   `type: {String} "apirequestfailed"`<br>
    *   `data: {Event} script.onerrorのハンドラに渡されたエラーオブジェクト`
    *
    ###
    @eventStream = new Rx.Subject()

    ###*
    * Flickr APIにリクエストを送る際の写真検索用のオプション設定オブジェクト<br>
    * その他のオプションは下記リンク参照<br>
    * <https://www.flickr.com/services/api/flickr.photos.search.htm><br>
    * @cfg {Object} options
    * @private
    * @cfg {String} [options.api_key="a3d606b00e317c733132293e31e95b2e"]
    * @cfg {String} [options.format="json"]
    * Flickr APIからのレスポンスの形式を指定する<br>
    * `json`を指定するとJSONP形式になる、JSONだけの応答が欲しい時は`nojsoncallback=1`を指定する必要がある
    * @cfg {String} [options.text=""]
    * 検索をする語句
    * @cfg {String} [options.sort="date-posted-desc"]
    * 並び順を指定する、規定値は投稿順
    * @cfg {Number} [options.per_page=0]
    * リクエストする写真の数
    ###
    @options =
      api_key       : 'a3d606b00e317c733132293e31e95b2e'
      format        : 'json'
      text          : ''
      sort          : 'date-posted-desc'
      per_page      : 0

    apiResponseStream.subscribe(
      (e) => @handleAPIResponse e.data
      (e) -> console.log 'jsonFlickrApi on apiresponse Error: ', e
      -> console.log 'jsonFlickrApi on apiresponse complete')

    ###*
    * 状態の変更を通知する為の機能をまとめたオブジェクト<br>
    * 状態を変更、監視、取得するための方法は{@link Stateful}を参照<br>
    * <h4>初期状態</h4>
    *
    *     {
    *         'waiting': false
    *     }
    *
    * <h4>各状態の意味</h4>
    * - **`waiting`**`: Boolean`<br>
    *   Flikcr APIからの応答を待っている場合`true`になる
    *
    * @member FlickrAPIManager
    * @property {Stateful} stateful
    * @mixin Stateful
    ###
    initialState = 'waiting': no
    makeStateful this, initialState

  ###*
  * Flickr APIにリクエストを送る際の写真検索用のオプションを設定する<br>
  * 与えられた設定オブジェクトは`FlickrAPIManager.options`にマージされる<br>
  * その他のオプションは下記リンク参照<br>
  * <https://www.flickr.com/services/api/flickr.photos.search.htm><br>
  * @accessor
  ###
  setOptions : (options) ->
    for own k, v of options
      @options[k] = v

  ###*
  * Flickr APIにリクエストを送る際の写真検索用のオプションに不正な値がないかチェック・修正する<br>
  * `FlickrAPIoptions.options`の値を検査して修正
  * @method validateOptions
  * @private
  ###
  validateOptions : ->
    try
      per_page = +@options.per_page
      throw new Error("per_page is NaN") if isNaN per_page
      negative = per_page <= 0
      @options.per_page = 1 if negative
    catch e
      console.log('Error in flickrAPIManager.validateOptions')
      console.log("message -> #{ e.message }")
      console.log("stack -> #{ e.stack }")
      console.log("fileName -> #{ e.fileName || e.sourceURL }")
      console.log("line -> #{ e.line || e.lineNumber }")

  ###*
  * Flickr APIにリクエストを送信する<br>
  * @param {Object} [options]
  * Flickr APIにリクエストを送る際の写真検索用のオプションを設定する<br>
  * `FlickrAPIManager.setOptions`に渡す`options`と同じもの
  * @return {Boolean}
  * すでにリクエストが送信された後でまだ応答を待っている状態の時`false`を返す<br>
  * return `false` when still waiting for API response
  ###
  sendRequestJSONP : (options) ->
    return false if @stateful.get 'waiting'
    @stateful.set 'waiting', yes
    newScript = document.createElement('script')
    oldScript = document.getElementById('kick-api')
    @setOptions(options) if options?
    @validateOptions()
    newScript.id = 'kick-api'
    newScript.src = @genRequestURI(@options)
    newScript.onerror = (e) =>
      @stateful.set 'waiting', no
      @eventStream.onNext
        'type': 'apirequestfailed'
        'data': e
    if oldScript?
      document.body.replaceChild(newScript, oldScript)
    else
      document.body.appendChild(newScript)
    @eventStream.onNext
      'type': 'sendrequest'
      'data': null
    return true


  ###*
  * 与えられたAPIオプションからFlickr APIを呼び出すためのHTTPリクエスト文字列を生成する<br>
  * フォーマットは以下のようになっている<br>
  *
  *     https://api.flickr.com/services/rest/?method=flickr.photos.search&{key}={value}&{key}={value}&...
  *
  * Generate HTTP request string to call Flickr API
  * @method genRequestURI
  * @param {Object} options  `FlickrAPIManager.options`参照
  * @return {String} HTTP request string
  * @private
  ###
  genRequestURI : (options) ->
    uri = ''
    for own k, v of options
      uri += "&#{k}=#{v}"
    return "https://api.flickr.com/services/rest/?method=flickr.photos.search#{uri}"

  ###*
  * FlickrのAPIレスポンスのJSONから写真の情報を抜き出してURLの配列を生成する<br>
  * JSONのフォーマットは下記のリンクを参照<br>
  * {@link jsonFlickrApi}<br>
  * 写真のURLのフォーマットは以下のようになっている<br>
  *
  *     http://farm{farm}.staticflickr.com/{server}/{id}_{secret}.jpg
  *
  * @method genPhotosURLArr
  * Generate array of photos URL from JSON of Flickr API response
  * @param {Object} json  JSON of Flickr API response
  * @private
  ###
  genPhotosURLArr : (json) ->
    for v, i in json.photos.photo
      "http://farm#{v.farm}.staticflickr.com/#{v.server}/#{v.id}_#{v.secret}.jpg"

  ###*
  * `jsonFlikcrApi.eventStream.subscribe`に渡す関数
  * @method handleAPIResponse
  * @param {Object} json  JSON of Flickr API response
  * @private
  ###
  handleAPIResponse : (json) ->
    if @stateful.get 'waiting'
      @stateful.set 'waiting', no
      @eventStream.onNext
        'type': 'apiresponse'
        'data': json
      @eventStream.onNext
        'type': 'urlready'
        'data': @genPhotosURLArr json


module.exports = new FlickrAPIManager
