/*
 *  publish.js and stateful.js are required for using this scripts.
 *
 * */

var renderer = {

  updaters : [],
  framerate: 16,
  timerID  : null,

  _state: {
    running: false,
    deleted: false
  },

  addUpdater: function (updater) {
    if        (updater instanceof Array) {
      this.updaters.concat(updater);

    } else if (typeof updater === "function") {
      this.updaters.push(updater);

    }
  },

  deleteUpdater: function (updater) {
    this._visitUpdaters("delete", updater);
  },

  _visitUpdaters: function (action, fn) {
    var updaters = this.updaters,
        updater,
        i = 0;

    while (updater = updaters[i]) {
      if (action === "delete" && updater === fn) {
        updaters[i]         = undefined;
        this._state.deleted = true;
      }
      i++;
    }
  },

  draw: function () {},

  pause: function () {
    clearInterval(this.timerID);
    this.changeState({ running: false });
  },

  makeDraw: function () {
    var _this = this,
        updaters = _this.updaters,
        updater,
        i, len;

    _this.draw = function () {
      if (_this._state.running) {
        return;
      }

      _this.changeState({ running: true });
      _this.timerID = setInterval(function () {

        for (i = 0, len = updaters.length; i < len; i++) {
          updater = updaters[i];
          try {
            updater();
          }
          catch (e) {
            console.log("updater : " + updater + "\ne : " + e);
          }

          if (i === len - 1 && _this._state.deleted) {
            for (i = 0; i < updaters.length;) {
              if (updaters[i] === undefined) {
                updaters.splice(i, 1);
              } else {
                i++;
              }
            }
            _this._state.deleted = false;
          }

        }

      }, _this.framerate);
    };

    return _this.draw;
  }

};

renderer.makeDraw();
makePublisher(renderer);
makeStateful (renderer);
