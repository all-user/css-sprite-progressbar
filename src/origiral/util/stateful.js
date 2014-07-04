var stateful = {

  _state: {},

  changeState: function (statusObj) {
    this._changeState(statusObj, false);
  },

  margeState: function (statusObj) {
    this._changeState(statusObj, true);
  },

  getState: function (prop) {
    if (typeof prop === "undefined") {
      console.log("getState : prop is empty");
    }
    return this._state[prop];
  },

  _changeState: function (statusObj, marge) {
    var state   = this._state,
        changed = false,
        type,
        status,
        newStatus;

    for (type in statusObj) {
      status = statusObj[type];

      if (
         state.hasOwnProperty(type) && state[type] !== status ||
        !state.hasOwnProperty(type) && marge
      ) {

        changed         = true;
        state[type]     = status;
        newStatus       = {};
        newStatus[type] = status;
        this.fire(type.toLowerCase() + "change", newStatus);  // newStatus ... { statusType: value }

      }
    }

    if (changed) {
      this.fire("statechange", state);
    }
  }

};

function makeStateful (o) {
  var i;
  for (i in stateful) {
    if (stateful.hasOwnProperty(i) && typeof stateful[i] === "function") {
      o[i] = stateful[i];
    }
  }
  o._state = o._state || {};
}
