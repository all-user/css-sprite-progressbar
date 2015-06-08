###*
* HTMLの以下の部分と密結合しており、写真の表示や削除などのDOM操作を行う<br>
*
*    <div id="photos-view"></div>
*
* @class PhotosView
* @constructor
* `PhotosView`のインスタンスを生成する
###
class PhotosView
  constructor: ->
    ###*
    * @property {Boolean[]} appended
    * `#photos-view`に写真を追加済みかどうかを`Boolean`で表す配列<br>
    * 追加済みの写真のインデックスに`true`が設定される
    ###
    @appended = []

  ###*
  * `div#photos-view`への参照を保持するプロパティ
  * @property {HTMLDivElement} elem
  ###
  elem:
    photosView: document.getElementById('photos-view')

  ###*
  * @method getAppended
  * `#photos-view`に写真が追加済みかどうかを`Boolean`で表す配列を返す<br>
  * `PhotosView.appended`への参照をそのまま返す
  * @return {Boolean[]}
  * `PhotosView.appended`への参照
  *
  ###
  getAppended: ->
    return @appended

  ###*
  * @method appendPhotos
  * 受け取った写真を表示する<br>
  * `imgArr`の中身を`#photos-view`に追加する<br>
  * `imgArr`は`<img>`(`HTMLImageElement`)の配列
  * @param {HTMLImageElement[]} imgArr
  * 追加する写真の配列<br>
  * `#photos-view`に追加する`<img>`(`HTMLImageElement`)の配列
  *
  ###
  appendPhotos : (imgArr) ->
    return unless imgArr?
    return if imgArr.length is 0
    frag = document.createDocumentFragment()
    sent = imgArr.sent
    for v, i in imgArr
      @appended[sent[i]] = yes
      frag.appendChild(v)
    @elem.photosView.appendChild(frag)

  ###*
  * @method clear
  * 写真を全て削除する<br>
  * `#photos-view`に追加された全ての要素を取り除き<br>
  * `PhotosView.appended`も空の配列で初期化される
  ###
  clear : ->
    view = @elem.photosView
    while view.firstChild
      view.firstChild.onload = null
      view.removeChild(view.firstChild)
    @appended = []

module.exports = new PhotosView
