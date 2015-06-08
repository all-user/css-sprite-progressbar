(function() {
  var DHTMLSprite, SpriteTile,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  DHTMLSprite = require('./dhtml-sprite');


  /**
  * `DHTMLSprite`クラスを使用したアニメーション作成する為のクラス
  * @class SpriteTile
  * @extends DHTMLSprite
  * @constructor
  * `SpriteTile`のインスタンスを生成する
  * @param {Object} options
  * `DHTMLSprite.options`<br>
  * `SpriteTile.options`を参照
  * @cfg {Object} options
  * `DHTMLSprite.options`に加え、以下のものを指定する
  * @cfg {Number} options.indexLength  スプライト画像のインデックスの長さ
  * @cfg {Number} options.x
  * 初期位置の指定、`x`は水平位置を表す<br>
  * `DHTMLSprite.draw`を参照
  * @cfg {Number} options.y
  * 初期位置の指定、`y`は垂直位置を表す<br>
  * `DHTMLSprite.draw`を参照
   */

  SpriteTile = (function(_super) {
    __extends(SpriteTile, _super);

    function SpriteTile(options) {
      var x, y;
      SpriteTile.__super__.constructor.call(this, options);
      x = options.x, y = options.y;
      this.index = 0;
      this.draw(x, y);
    }


    /**
    * @method update
    * スプライトの画像を順に切り替える<br>
    * 一定間隔で呼び出すことでアニメーションさせることができる
    * @param {Number} amount
    * ここで指定した値がインデックスに加算される<br>
    * `1`を指定すると呼び出す度に次の画像に切り替わる<br>
    * `0.5`の場合、２回に１回のペースで次の画像に切り替わる<br>
    * {@link TimeInfo}と組み合わせて使うことで、呼び出しの間隔に振れ幅があった場合にインデックスのを調整することができる
     */

    SpriteTile.prototype.update = function(amount) {
      this.index += amount;
      this.index %= this.options.indexLength;
      return this.changeImage(this.index | 0);
    };

    return SpriteTile;

  })(DHTMLSprite);

  module.exports = SpriteTile;

}).call(this);
