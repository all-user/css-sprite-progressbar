Rx = require 'rx'

###*
* 状態の変更を通知する為の機能をまとめたオブジェクト<br>
* `makeStateful`を使ってこのオブジェクトの機能を他のオブジェクトに付与する<br>
*
*     var makeStateful = require('./stateful').makeStateful;
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
*         makeStateful(this, initState);
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
*     }).subscribe(function() {
*         console.log('lenna was poisoned!');
*     });
*
*     bio(lenna); //   lenna was poisoned!
*
* @class Stateful
* @uses Rx.Subject
* @constructor
* `Stateful`のインスタンスを生成する
* @param {Object} initState
* インスタンスの持つプロパティ名と初期状態をオブジェクトで指定する
###
class Stateful
  constructor: (initState)->
    ###*
    * @property {Object} _state
    * `Stateful`が管理する実際の値を保持するオブジェクト<br>
    * 値の更新は`Stateful.set`、取得は`Stateful.get`で行う
    *
    * @private
    ###
    @_state = initState
    ###*
    * @property {Rx.Subject} stream
    * `Stateful.set`によってプロパティが変更された時にイベントが流れてくるRx.Subjectのインスタンス<br>
    * `.subscribe(observer)`で購読できる<br>
    * [RxJS Doc: Creating and subscribing to a simple sequence](https://github.com/Reactive-Extensions/RxJS/blob/master/doc/gettingstarted/creating.md#user-content-creating-and-subscribing-to-a-simple-sequence)
    *
    * Stream the events when the property changed by `Stateful.set`<br>
    * this is instance of Rx.Subject<br>
    *
    *     var Stateful = require('./stateful');
    *
    *     var initState = { waiting: false };
    *     var stateful  = new Stateful(initState);
    *
    *     stateful.stream
    *     .map(function(state) { return state.waiting; })
    *     .subscribe(function(waiting) {
    *         console.log("state was changed: %s", waiting);
    *     });
    *
    *     stateful.set({     // state was changed: true
    *         waiting: true
    *     });
    *
    *
    * 特定のプロパティの変更のみを通知したいときは`Rx.Observable.prototype.distinctUntilChanged`を使う
    *
    *     var Stateful = require('./stateful');
    *
    *     var initState = {
    *         waiting  : false,
    *         direction: "up"
    *     };
    *     var stateful = new Stateful(initState);
    *
    *     var waitingChange = stateful.stream.distinctUntilChanged(function(state) {
    *         return state.waiting;
    *     });
    *
    *     waitingChange
    *     .map(function(state) { return state.waiting; })
    *     .subscribe(function(waiting) {
    *         console.log('"waiting" was changed: %s', waiting);
    *     });
    *
    *     stateful.set({     // "waiting" was changed: true
    *         waiting: true
    *     });
    *
    *
    * <h4>Event Format</h4>
    * `_state`への参照がそのまま渡される
    *
    * Stream the refarence to `_state`
    *
    ###
    @stream = new Rx.Subject

  ###*
  * 任意の状態を新しい値に書き換える<br>
  * 引数はプロパティ名と値を別々に渡すか、オブジェクトを一つだけ渡す<br>
  * オブジェクトの場合は複数の状態を同時に指定可能
  *
  *     var initState = {
  *         waiting: false,
  *         stun   : false
  *     };
  *     var stateful = new Stateful(initState);
  *
  *     stateful.set('waiting', true);
  *
  *     stateful.set({
  *         waiting: false,
  *         stun   : true
  *     });
  *
  * @method set
  * @param {String/Object} prop
  * 新しい値を代入するプロパティ名、もしくはプロパティ名と値のセットをオブジェクトで指定する
  * @param {Any} [value]
  * 第一引数がプロパティ名の指定だった場合、第二引数に代入したい値を指定する
  ###
  set : (prop, value) ->
    if typeof prop is 'object'
      @_changeState(prop, no)
    else if typeof prop is 'string'
      obj = {}
      obj[prop] = value
      @_changeState(obj, no)
    else
      throw new Error 'type error at arguments'

  ###*
  * 任意の状態の値を取得する<br>
  *
  *     var initState = {
  *         waiting: false,
  *         stun   : false
  *     };
  *     var stateful = new Stateful(initState);
  *
  *     stateful.set('waiting', true);
  *
  *     var isWaiting = stateful.get('waiting');
  *     if (isWaiting) {
  *         console.log('waiting now'); //    waiting now
  *     }
  *
  * @method get
  * @param {String/Object} prop
  * 値を取得するプロパティ名を指定する
  * @return {Any}
  * 指定されたプロパティ名の値を返す
  ###
  get: (prop) ->
    if prop?
      @_state[prop]
    else
      o = {}
      o[prop] = value for prop, value of @_state
      o

  ###*
  * `Stateful.set`と同じだが、元のオブジェクトが持っていないプロパティ名のみ`Stateful._state`にマージする<br>
  * 元の状態には変更を加えず、元の状態に無い新しいプロパティのみ追加する<br>
  * プロパティ名を持っているかどうかは`Object.prototype.hasOwnProperty`を使用して確認する
  * @method setOnlyUndefinedProp
  ###
  setOnlyUndefinedProp: (statusObj) ->
    @_changeState(statusObj, yes)

  ###*
  * @method _changeState
  * @private
  ###
  _changeState : (statusObj, onlyUndefined) ->
    changed = no
    for type, status of statusObj
      changeOwnProp = @_state.hasOwnProperty(type) and @_state[type] isnt status
      onlyUndefinedProp = not @_state.hasOwnProperty(type) and onlyUndefined
      if changeOwnProp or onlyUndefinedProp
        changed = yes
        @_state[type] = status
        newStatus = {}
        newStatus[type] = status
    @stream.onNext @_state if changed

  ###*
  * 第一引数で受け取ったオブジェクトに`stateful`というプロパティを作り、<br>
  * `new Stateful(initState)`したインスタンスを代入する
  *
  *     o.stateful = new Stateful(initState);
  *
  * @method makeStateful
  * @static
  * @param {Object} o
  * @param {Object} initState
  ###
  @makeStateful: (o, initState) ->
    o.stateful ?= new Stateful initState

module.exports = Stateful
