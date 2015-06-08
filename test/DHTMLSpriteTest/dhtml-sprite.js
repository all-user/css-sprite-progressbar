
/**
* CSSスプライトを作成・描画・更新するクラス<br>
* `div`要素の`background-position`を書き換えて表示する画像を切り替える
*
*     var options = {
*         width      : 50,
*         height     : 50,
*         imagesWidth: 200,
*         images     : './images/wheel.png',
*         drawTarget : document.getElementById('sprite-canvas')
*     };
*     var sprite = new DHTMLSprite(options);
*
*     sprite.draw(150, 80);
*
*     sprite.changeImage(5);
*
* @class DHTMLSprite
* @constructor
* `DHTMLSprite`のインスタンスを生成する
* @param {Object} options
* `DHTMLSprite.options`を参照
* @cfg {Object} options
* @cfg {Number} options.width  表示領域の幅（px）
* @cfg {Number} options.height  表示領域の高さ（px）
* @cfg {Number} options.imagesWidth  スプライト画像の幅（px）
* @cfg {String} options.images  スプライト画像のURL
* @cfg {Node} options.drawTarget
* アニメーションを描画する親要素<br>
* この要素の子要素として`position: absolute;`で配置される
*
 */

(function() {
  var DHTMLSprite;

  DHTMLSprite = (function() {
    function DHTMLSprite(options) {
      var height, images, imagesWidth, width;
      this.options = options;
      width = options.width, height = options.height, imagesWidth = options.imagesWidth, images = options.images;
      this.element = document.createElement('div');
      options.drawTarget.appendChild(this.element);
      this.element.style.position = 'absolute';
      this.element.style.width = "" + width + "px";
      this.element.style.height = "" + height + "px";
      this.element.style.backgroundImage = "url(" + images + ")";
    }


    /**
    * @method draw
    * 位置を指定しスプライトを描画する<br>
    * 内部的には`div`の`top`、`left`を指定しているだけなので、<br>
    * 表示の有無に関しては`DHTMLSprite.show`、`DHTMLSprite.hide`を使う
    * @param {Number} x
    * スプライトを描画する水平位置を指定する<br>
    * 内部的には`style`に以下を指定している
    *
    *     left: (x)px;
    *
    * @param {Number} y
    * スプライトを描画する垂直位置を指定する<br>
    * 内部的には`style`に以下を指定している
    *
    *     top: (y)px;
    *
     */

    DHTMLSprite.prototype.draw = function(x, y) {
      this.element.style.left = "" + x + "px";
      return this.element.style.top = "" + y + "px";
    };


    /**
    * @method changeImage
    * スプライトの画像をインデックスを指定して切り替える
    * @param {Number} index
    * スプライトのインデックス
     */

    DHTMLSprite.prototype.changeImage = function(index) {
      var hOffset, vOffset;
      index *= this.options.width;
      vOffset = -(index / this.options.imagesWidth | 0) * this.options.height;
      hOffset = -index % this.options.imagesWidth;
      return this.element.style.backgroundPosition = "" + hOffset + "px " + vOffset + "px";
    };


    /**
    * @method show
    * スプライトを表示する<br>
    * 内部的には`style`に`display: block;`を指定している
     */

    DHTMLSprite.prototype.show = function() {
      return this.element.style.display = 'block';
    };


    /**
    * @method hide
    * スプライトを非表示にする<br>
    * 内部的には`style`に`display: none;`を指定している
     */

    DHTMLSprite.prototype.hide = function() {
      return this.element.style.display = 'none';
    };


    /**
    * @method destroy
    * スプライトを破棄する<br>
    * 内部的には`ChildNode.remove`を使用してDOMを親要素から取り除いている
     */

    DHTMLSprite.prototype.destroy = function() {
      return this.element.remove();
    };

    return DHTMLSprite;

  })();

  module.exports = DHTMLSprite;

}).call(this);
