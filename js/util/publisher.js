var publisher = {

  _subscribers: {
    any: []
  },

  on: function (type, fn, context) {
    type = type || "any";
    fn   = typeof fn === "function" ? fn : context[fn];

    if (typeof this._subscribers[type] === "undefined") {
      this._subscribers[type] = [];
    }

    this._subscribers[type].push({ fn: fn, context: context || this});
  },

  remove: function (type, fn, context) {
    this.visitSubscribers("unsubscribe", type, fn, context);
  },

  fire: function (type, publication) {
    this.visitSubscribers("publish", type, publication);
  },

  visitSubscribers: function (action, type, arg) {
    var pubtype     = type || "any",
        subscribers = this._subscribers[pubtype],
        max         = subscribers ? subscribers.length : 0,
        i;

    for (i = 0; i < max; i += 1) {
      if (action === "publish") {
        try {
          subscribers[i].fn.call(subscribers[i].context, arg);
        }
        catch (e) {
          console.log(pubtype + " : " + e);
        }

      } else {
        if (subscribers[i].fn === arg && subscribers[i].context === context) {
          subscribers.splice(i, 1);
        }
      }
    }

  }


};

function makePublisher (o) {
  var i;
  for (i in publisher) {
    if (publisher.hasOwnProperty(i) && typeof publisher[i] === "function") {
      o[i] = publisher[i];
    }
  }
  o._subscribers = { any: [] };
}
