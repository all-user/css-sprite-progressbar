/*
 *  publish.js and stateful.js are required for using this scripts.
 *
 * */

var progressbarModel = {

  _state: {
    hidden        : true,
    fading        : "stop",
    flowSpeed     : "slow",
    denominator   : 0,
    numerator     : 0,
    progress      : 0,
    canRenderRatio: false,
    canQuit       : false
  },

  speed: {
    type : { stop: 0,  slow: 1,  middle: 2,  fast: 3 },
    array: ["stop"  , "slow"  , "middle"  , "fast"   ]
  },

  processType: { ceil: "ceil", floor: "floor", round: "round" },

  run: function () {
    this.fire("run" , this);
  },

  stop: function () {
    this.fire("stop", this);
  },

  clear: function () {
    this.changeState({
      denominator   : 0,
      numerator     : 0,
      progress      : 0,
      canRenderRatio: true,
      canQuit       : false
    });
    this.fire("clear", null);
  },

  fadeIn: function () {
    this.changeState({ fading: "in"   });
  },

  fadeOut: function () {
    this.changeState({ fading: "out"  });
  },

  fadeStop: function () {
    this.changeState({ fading: "stop" });
  },

  setFlowSpeed: function (speed) {
    if (this.speed.type.hasOwnProperty(speed)) {
      this.changeState({ flowSpeed: speed });
    }
  },

  flowMoreFaster: function () {
    var currentSpeed = this.speed.type[ this._state.flowSpeed ];
    this.setFlowSpeed(this.speed.array[ ++currentSpeed ]);
  },

  flowMoreSlower: function () {
    var currentSpeed = this.speed.type[ this._state.flowSpeed ];
    this.setFlowSpeed(this.speed.array[ --currentSpeed ]);
  },

  setDenominator: function (denomi) {
    this._setProgress("denominator", denomi);
  },

  setNumerator: function (numer) {
    this._setProgress("numerator"  , numer );
  },

  _setProgress: function (type, value) {
    var o = {};
    o[type] = value;
    this.changeState(o);
    this.changeState({
      progress      : this.getProgress(),
      canRenderRatio: true
    });
  },

  getProgress: function (process) {
    var res = this._state.numerator / this._state.denominator;
    if (this.processType.hasOwnProperty(process)) {
      Math[ this.processType[ process ] ](res);
    }
    return res;
  }

};

makePublisher(progressbarModel);
makeStateful (progressbarModel);
