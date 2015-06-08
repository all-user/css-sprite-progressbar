(function() {
  var Rx, Stateful;

  Rx = require('rx');


  /**
  * 状態の変更を通知する為の機能をまとめたオブジェクト<br>
  * `makeStateful`を使ってこのオブジェクトの機能を他のオブジェクトに付与する<br>
  *
  *     var makeStateful = require('./src/make-stateful');
  *
  *     function Player(name) {
  *         this.name = name;
  *
  *         var initState = {
  *             poison  : false,
  *             confuse : false,
  *             sleep   : false,
  *             silence : false,
  *             darkness: false,
  *             berserk : false,
  *             petrify : false,
  *             reflect : false,
  *             vanish  : false,
  *             toad    : false,
  *             levitate: false
  *         };
  *
  *         makeStateful(this, initState)
  *     }
  *
  *     var lenna = new Player("lenna");
  *
  *     var bio = function(player) {
  *         player.stateful.set({
  *             poison: true
  *         });
  *     };
  *
  *     lenna.stateful.stream.distinctUntilChanged(function(state) {
  *         return state.poison;
  *     }).subscribe(function(state) {
  *         console.log('lenna was poisoned!');
  *     });
  *
  *     bio(lenna); //   lenna was poisoned!
  *
  * @class Stateful
  * @uses Rx.Subject
   */

  Stateful = (function() {

    /**
    * @constructor
    * `Stateful`のインスタンスを生成する
     */
    function Stateful(initState) {

      /**
      * @property {Object} _state
      * `Stateful`が管理する実際の値を保持するオブジェクト<br>
      * 値の更新は`Stateful.set`、取得は`Stateful.get`で行う
      *
      * @private
       */
      this._state = initState;

      /**
      * @property {Rx.Subject} stream
      * `Stateful.set`によってプロパティが変更された時にイベントが流れてくるRx.Subjectのインスタンス<br>
      * `.subscribe(observer)`で購読できる<br>
      * [RxJS Doc: Creating and subscribing to a simple sequence](https://github.com/Reactive-Extensions/RxJS/blob/master/doc/gettingstarted/creating.md#user-content-creating-and-subscribing-to-a-simple-sequence)
      *
      * Stream the events when the property changed by `Stateful.set`<br>
      * this is instance of Rx.Subject<br>
      *
      *     var stateful = new Stateful({
      *         waiting: false
      *     });
      *
      *     stateful.stream.subscribe(function(state) {
      *       console.log(state.waiting);
      *     });
      *
      *     stateful.set({
      *         waiting: true
      *     });
      *     // true
      *
      * 特定のプロパティの変更のみを通知したいときは`Rx.Observable.prototype.distinctUntilChanged`を使う
      *
      *     var stateful = new Stateful({
      *         waiting  : false,
      *         direction: "up"
      *     });
      *
      *     var waitingChange = stateful.stream
      *         .distinctUntilChanged(function(state) {
      *             return state.waiting;
      *         });
      *
      *     waitingChange.subscribe(function(state) {
      *       console.log(state.waiting);
      *     });
      *
      *     stateful.set({
      *         waiting: true
      *     });
      *     // true
      *
      * <h4>Event Format</h4>
      * `_state`への参照がそのまま渡される
      *
      * Stream the refarence to `_state`
      *
      *     {
      *         "state name": "state value"
      *     }
       */
      this.stream = new Rx.Subject;
    }


    /**
    * @method set
    * <h4>Stateful.prototype.set</h4>
     */

    Stateful.prototype.set = function(prop, value) {
      var obj;
      if (typeof prop === 'object') {
        return this._changeState(prop, false);
      } else if (typeof prop === 'string') {
        obj = {};
        obj[prop] = value;
        return this._changeState(obj, false);
      } else {
        throw new Error('type error at arguments');
      }
    };


    /**
    * @method get
    * @param {String/Object} prop
    * @return {Any/Object}
    * <h4>Stateful.prototype.get</h4>
     */

    Stateful.prototype.get = function(prop) {
      var o, value, _ref;
      if (prop != null) {
        return this._state[prop];
      } else {
        o = {};
        _ref = this._state;
        for (prop in _ref) {
          value = _ref[prop];
          o[prop] = value;
        }
        return o;
      }
    };


    /**
    * @method setOnlyUndefinedProp
    * <h4>Stateful.prototype.setOnlyUndefinedProp</h4>
     */

    Stateful.prototype.setOnlyUndefinedProp = function(statusObj) {
      return this._changeState(statusObj, true);
    };


    /**
    * @method _changeState
    * <h4>Stateful.prototype._changeState</h4>
    * @private
     */

    Stateful.prototype._changeState = function(statusObj, onlyUndefined) {
      var changeOwnProp, changed, newStatus, onlyUndefinedProp, status, type;
      changed = false;
      for (type in statusObj) {
        status = statusObj[type];
        changeOwnProp = this._state.hasOwnProperty(type) && this._state[type] !== status;
        onlyUndefinedProp = !this._state.hasOwnProperty(type) && onlyUndefined;
        if (changeOwnProp || onlyUndefinedProp) {
          changed = true;
          this._state[type] = status;
          newStatus = {};
          newStatus[type] = status;
        }
      }
      if (changed) {
        return this.stream.onNext(this._state);
      }
    };


    /**
    * @method makeStateful
    * @static
    * @param {Object} o
    * @param {Object} initState
    * `makeStateful`は第一引数で受け取ったオブジェクトに`stateful`というプロパティを作り、<br>
    * `new Stateful(initState)`したインスタンスを代入する
     */

    Stateful.makeStateful = function(o, initState) {
      return o.stateful != null ? o.stateful : o.stateful = new Stateful(initState);
    };

    return Stateful;

  })();

  module.exports = Stateful;

}).call(this);
