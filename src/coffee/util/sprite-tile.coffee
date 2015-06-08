DHTMLSprite = require './dhtml-sprite'

###*
* `DHTMLSprite`クラスを使用したアニメーション作成する為のクラス
*
*     var options = {
*         width      : 50,
*         height     : 50,
*         imagesWidth: 200,
*         images     : './images/wheel.png',
*         drawTarget : document.getElementById('sprite-canvas')
*         x          : 150,
*         y          : 80,
*         indexLength: 8
*     };
*     var sprite = new SpriteTile(options);
*
*     var timerID = setInterval(function() {
*         sprite.update(1);
*     }, 50);
*
* @class SpriteTile
* @extends DHTMLSprite
* @constructor
* `SpriteTile`のインスタンスを生成する
* @param {Object} options
* `DHTMLSprite.options`<br>
* `SpriteTile.options`を参照
* @cfg {Object} options (required)
* `DHTMLSprite.options`に加え、以下のものを指定する
* @cfg {Number} options.indexLength  スプライト画像のインデックスの長さ
* @cfg {Number} options.x
* 初期位置の指定、`x`は水平位置を表す<br>
* `DHTMLSprite.draw`を参照
* @cfg {Number} options.y
* 初期位置の指定、`y`は垂直位置を表す<br>
* `DHTMLSprite.draw`を参照
###
class SpriteTile extends DHTMLSprite
  constructor: (options) ->
    super options
    { x, y } = options
    @index = 0
    @draw x, y

  ###*
  * @method update
  * スプライトの画像を順に切り替える<br>
  * 一定間隔で呼び出すことでアニメーションさせることができる
  * @param {Number} amount
  * ここで指定した値がインデックスに加算される<br>
  * `1`を指定すると呼び出す度に次の画像に切り替わる<br>
  * `0.5`の場合、２回に１回のペースで次の画像に切り替わる<br>
  * {@link TimeInfo}と組み合わせて使うことで、呼び出しの間隔に振れ幅があった場合にインデックスのを調整することができる
  ###
  update: (amount) ->
    @index += amount
    @index %= @options.indexLength
    @changeImage @index | 0

module.exports = SpriteTile
