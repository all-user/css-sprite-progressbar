(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var flickrApiManager, makePublisher, makeStateful,
  __hasProp = {}.hasOwnProperty;

makePublisher = require('../util/publisher');

makeStateful = require('../util/stateful');

window.jsonFlickrApi = function(json) {
  return jsonFlickrApi.fire('apiresponse', json);
};

flickrApiManager = {
  apiOptions: {
    apiKey: 'a3d606b00e317c733132293e31e95b2e',
    format: 'json',
    noJsonCallback: false,
    others: {
      text: '',
      sort: 'date-posted-desc',
      per_page: 0
    }
  },
  _state: {
    waiting: false
  },
  setAPIOptions: function(options) {
    var k, v, _results;
    _results = [];
    for (k in options) {
      if (!__hasProp.call(options, k)) continue;
      v = options[k];
      if (this.apiOptions.hasOwnProperty(k)) {
        _results.push(this.apiOptions[k] = v);
      } else {
        _results.push(this.apiOptions.others[k] = v);
      }
    }
    return _results;
  },
  validateOptions: function() {
    var e, negative, perPage;
    try {
      perPage = +this.apiOptions.others.per_page;
      if (isNaN(perPage)) {
        throw new Error("per_page is NaN");
      }
      negative = perPage < 0;
      if (negative) {
        return this.apiOptions.others.per_page = 0;
      }
    } catch (_error) {
      e = _error;
      console.log('Error in flickrApiManager.validateOptions');
      console.log("message -> " + e.message);
      console.log("stack -> " + e.stack);
      console.log("fileName -> " + (e.fileName || e.sourceURL));
      return console.log("line -> " + (e.line || e.lineNumber));
    }
  },
  sendRequestJSONP: function(options) {
    var newScript, oldScript;
    if (this._state.waiting) {
      return false;
    }
    this.changeState({
      'waiting': true
    });
    newScript = document.createElement('script');
    oldScript = document.getElementById('kick-api');
    if (options != null) {
      this.setAPIOptions(options);
    }
    this.validateOptions();
    newScript.id = 'kick-api';
    newScript.src = this.genURI(this.apiOptions);
    if (oldScript != null) {
      document.body.replaceChild(newScript, oldScript);
    } else {
      document.body.appendChild(newScript);
    }
    return this.fire('sendrequest', null);
  },
  genURI: function(options) {
    var k, noJsonp, uri, v, _ref;
    uri = "api_key=" + options.apiKey;
    _ref = options.others;
    for (k in _ref) {
      if (!__hasProp.call(_ref, k)) continue;
      v = _ref[k];
      uri += "&" + k + "=" + v;
    }
    uri += "&format=" + options.format;
    noJsonp = options.format === 'json' && options.noJsonCallback;
    if (noJsonp) {
      uri += 'noJsonCallback';
    }
    return "https://api.flickr.com/services/rest/?method=flickr.photos.search&" + uri;
  },
  genPhotosURLArr: function(json) {
    var i, v, _i, _len, _ref, _results;
    _ref = json.photos.photo;
    _results = [];
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      v = _ref[i];
      _results.push("http://farm" + v.farm + ".staticflickr.com/" + v.server + "/" + v.id + "_" + v.secret + ".jpg");
    }
    return _results;
  },
  handleAPIResponse: function(json) {
    this.changeState({
      'waiting': false
    });
    this.fire('apiresponse', json);
    return this.fire('urlready', this.genPhotosURLArr(json));
  }
};

makePublisher(jsonFlickrApi);

makePublisher(flickrApiManager);

makeStateful(flickrApiManager);

jsonFlickrApi.on('apiresponse', 'handleAPIResponse', flickrApiManager);

module.exports = flickrApiManager;


},{"../util/publisher":7,"../util/stateful":8}],2:[function(require,module,exports){
var exports,
  __hasProp = {}.hasOwnProperty;

exports = this;

document.addEventListener('DOMContentLoaded', function() {
  exports.inputView = {
    el: {
      searchText: document.getElementById('search-text'),
      perPage: document.getElementById('per-page'),
      maxReq: document.getElementById('max-req'),
      searchButton: document.getElementById('search-button'),
      canselButton: document.getElementById('cansel-button'),
      photosView: document.getElementById('photos-view')
    },
    getOptions: function() {
      var k, options;
      options = {
        text: this.el.searchText.value,
        per_page: this.el.perPage.value
      };
      for (k in options) {
        if (!__hasProp.call(options, k)) continue;
        if (options[k] === '') {
          delete options[k];
        }
      }
      return options;
    },
    getMaxConcurrentRequest: function() {
      var maxReq;
      maxReq = this.el.maxReq.value;
      return maxReq != null ? maxReq : false;
    },
    handleClick: function(e) {
      return this.fire('searchclick', e);
    },
    handleCansel: function(e) {
      console.log('canselclick');
      return this.fire('canselclick', e);
    }
  };
  makePublisher(inputView);
  inputView.el.searchButton.addEventListener('click', inputView.handleClick.bind(inputView));
  return inputView.el.canselButton.addEventListener('click', inputView.handleCansel.bind(inputView));
});


},{}],3:[function(require,module,exports){
var flickrApiManager, inputView, photosModel, progressbarModel, progressbarView;

flickrApiManager = require('../flickr/flickr-api-manager');

photosModel = require('../photos/photos-model');

progressbarModel = require('../progressbar/progressbar-model');

progressbarView = require('../progressbar/progressbar-view');

inputView = require('../input/input-view');

document.addEventListener('DOMContentLoaded', function() {
  var mediator;
  mediator = {
    store: {},
    setDenomiPhotosLength: function(urlArr) {
      return progressbarModel.setDenominator(urlArr.length);
    },
    checkCanQuit: function() {
      var bool;
      bool = !flickrApiManager.getState('waiting') && photosModel.getState('completed');
      return progressbarModel.changeState({
        canQuit: bool
      });
    },
    decideFlowSpeed: function() {
      var speed;
      speed = progressbarView.getState('full') ? 'fast' : flickrApiManager.getState('waiting') ? 'slow' : 'middle';
      return progressbarModel.setFlowSpeed(speed);
    },
    handleFading: function(statusObj) {
      var action;
      action = statusObj.fading;
      switch (action) {
        case 'stop':
          return renderer.deleteUpdater(this.store.fadingUpdater);
        default:
          this.store.fadingUpdater = progressbarView.fadingUpdate;
          return renderer.addUpdater(this.store.fadingUpdater);
      }
    },
    handleButtonClick: function() {
      progressbarModel.run();
      photosModel.clear();
      flickrApiManager.setAPIOptions(inputView.getOptions());
      photosModel.setProperties({
        maxConcurrentRequest: inputView.getMaxConcurrentRequest()
      });
      return flickrApiManager.sendRequestJSONP();
    }
  };
  flickrApiManager.on('urlready', 'initPhotos', photosModel);
  inputView.on('cancelclick', 'clearUnloaded', photosModel);
  flickrApiManager.on('urlready', 'setDenomiPhotosLength', mediator);
  photosModel.on('clearunloaded', 'setDenominator', progressbarModel);
  photosModel.on('loadedincreased', 'setNumerator', progressbarModel);
  flickrApiManager.on('waitingchange', 'checkCanQuit', mediator);
  photosModel.on('completedchange', 'checkCanQuit', mediator);
  flickrApiManager.on('waitingchange', 'decideFlowSpeed', mediator);
  photosModel.on('clear', 'clear', progressbarModel);
  progressbarView.on('fullchange', 'decideFlowSpeed', mediator);
  progressbarModel.on('fadingchange', 'handleFading', mediator);
  progressbarModel.on('run', 'draw', renderer);
  progressbarModel.on('stop', 'pause', renderer);
  return inputView.on('searchclick', 'handleButtonClick', mediator);
});


},{"../flickr/flickr-api-manager":1,"../input/input-view":2,"../photos/photos-model":4,"../progressbar/progressbar-model":5,"../progressbar/progressbar-view":6}],4:[function(require,module,exports){
var makePublisher, makeStateful, photosModel,
  __hasProp = {}.hasOwnProperty;

makePublisher = require('../util/publisher');

makeStateful = require('../util/stateful');

photosModel = {
  maxConcurrentRequest: 0,
  allRequestSize: 0,
  loadedSize: 0,
  photosURLArr: [],
  unloadedURLArr: [],
  photosArr: [],
  _state: {
    validated: false,
    completed: false
  },
  clear: function() {
    this.changeState({
      validated: false,
      completed: false
    });
    this.setProperties({
      maxConcurrentRequest: 0,
      allRequestSize: 0,
      loadedSize: 0,
      photosURLArr: [],
      unloadedURLArr: [],
      photosArr: []
    });
    return this.fire('clear', null);
  },
  clearUnloaded: function() {
    this.setProperties({
      unloadedURLArr: []
    });
    console.log('clearunloaded');
    return this.fire('clearunloaded', this.loadedSize);
  },
  incrementLoadedSize: function() {
    this.loadedSize++;
    this.fire('loadedincreased', photosModel.loadedSize);
    if (this.loadedSize === this.allRequestSize) {
      return this.changeState({
        completed: true
      });
    }
  },
  initPhotos: function(urlArr) {
    this.setProperties({
      photosURLArr: urlArr,
      allRequestSize: urlArr.length
    });
    this.validateProperties();
    return this.loadPhotos();
  },
  loadPhotos: function() {
    return this._load(this.maxConcurrentRequest);
  },
  loadNext: function() {
    return this._load(1);
  },
  _load: function(size) {
    if (this.unloadedURLArr.length === 0) {
      return;
    }
    return this.fire('delegateloading', this.unloadedURLArr.splice(0, size));
  },
  addPhoto: function(img) {
    this.photosArr.push(img);
    return this.incrementLoadedSize();
  },
  setProperties: function(props) {
    var k, v;
    for (k in props) {
      if (!__hasProp.call(props, k)) continue;
      v = props[k];
      if (this.hasOwnProperty(k)) {
        this[k] = v;
      }
    }
    return this.changeState({
      validated: false
    });
  },
  validateProperties: function() {
    var e;
    try {
      this.maxConcurrentRequest |= 0;
      this.allRequestSize |= 0;
      if (isNaN(this.maxConcurrentRequest)) {
        throw new Error('maxConcurrentRequest is Nan');
      }
      if (isNaN(this.allRequestSize)) {
        throw new Error('allRequestSize is Nan');
      }
      this.maxConcurrentRequest = this.maxConcurrentRequest > this.allRequestSize ? this.allRequestSize : this.maxConcurrentRequest > 0 ? this.maxConcurrentRequest : 0;
      this.unloadedURLArr = this.photosURLArr.slice();
      return this.changeState({
        validated: true
      });
    } catch (_error) {
      e = _error;
      console.log('Error in photosModel.validateProperties');
      console.log("message -> " + e.message);
      console.log("stack -> " + e.stack);
      console.log("fileName -> " + (e.fileName || e.sourceURL));
      return console.log("line -> " + (e.line || e.lineNumber));
    }
  },
  getNextPhoto: function(received) {
    return this._getPhotosArr(received, 1);
  },
  _getPhotosArr: function(received, length) {
    var i, j, res, sent, v, _i, _j, _len;
    sent = [];
    res = [];
    if (received != null) {
      if (typeof received === 'number') {
        res.push(this.photosArr[received].cloneNode());
        sent = [received];
      } else {
        j = 0;
        for (i = _i = 0; 0 <= length ? _i < length : _i > length; i = 0 <= length ? ++_i : --_i) {
          while (received[j]) {
            j++;
          }
          if (this.photosArr[j] == null) {
            break;
          }
          res[i] = this.photosArr[j].cloneNode();
          sent[i] = j;
        }
      }
    } else {
      res = this.photosArr.slice(0, length);
      for (i = _j = 0, _len = res.length; _j < _len; i = ++_j) {
        v = res[i];
        res[i] = v.cloneNode();
        sent[i] = i;
      }
    }
    res.sent = sent;
    return res;
  }
};

makePublisher(photosModel);

makeStateful(photosModel);

module.exports = photosModel;


},{"../util/publisher":7,"../util/stateful":8}],5:[function(require,module,exports){
var makePublisher, makeStateful, progressbarModel;

makePublisher = require('../util/publisher');

makeStateful = require('../util/stateful');

progressbarModel = {
  _state: {
    hidden: true,
    fading: 'stop',
    flowSpeed: 'slow',
    denominator: 0,
    numerator: 0,
    progress: 0,
    canRenderRatio: false,
    canQuit: false
  },
  speed: {
    type: {
      stop: 0,
      slow: 1,
      middle: 2,
      fast: 3
    },
    array: ['stop', 'slow', 'middle', 'fast']
  },
  processType: {
    ceil: 'ceil',
    floor: 'floor',
    round: 'round'
  },
  run: function() {
    return this.fire('run', this);
  },
  stop: function() {
    return this.fire('stop', this);
  },
  clear: function() {
    this.changeState({
      denominator: 0,
      numerator: 0,
      progress: 0,
      canRenderRatio: true,
      canQuit: false
    });
    return this.fire('clear', null);
  },
  fadeIn: function() {
    return this.changeState({
      fading: 'in'
    });
  },
  fadeOut: function() {
    return this.changeState({
      fading: 'out'
    });
  },
  fadeStop: function() {
    return this.changeState({
      fading: 'stop'
    });
  },
  setFlowSpeed: function(speed) {
    if (this.speed.type.hasOwnProperty(speed)) {
      return this.changeState({
        flowSpeed: speed
      });
    }
  },
  flowMoreFaster: function() {
    var currentSpeed;
    currentSpeed = this.speed.type[this._state.flowSpeed];
    return this.setFlowSpeed(this.speed.array[currentSpeed + 1]);
  },
  flowMoreSlower: function() {
    var currentSpeed;
    currentSpeed = this.speed.type[this._state.flowSpeed];
    return this.setFlowSpeed(this.speed.array[currentSpeed - 1]);
  },
  setDenominator: function(denomi) {
    return this._setProgress('denominator', denomi);
  },
  setNumerator: function(numer) {
    return this._setProgress('numerator', numer);
  },
  _setProgress: function(type, value) {
    var o;
    o = {};
    o[type] = value;
    this.changeState(o);
    return this.changeState({
      progress: this.getProgress(),
      canRenderRatio: true
    });
  },
  getProgress: function(process) {
    var res;
    res = this._state.numerator / this._state.denominator;
    if (this.processType.hasOwnProperty(process)) {
      Math[this.processType[process]](res);
    }
    return res;
  }
};

makePublisher(progressbarModel);

makeStateful(progressbarModel);


},{"../util/publisher":7,"../util/stateful":8}],6:[function(require,module,exports){
var exports;

exports = this;

document.addEventListener('DOMContentLoaded', function() {
  exports.progressbarView = {
    el: {
      gaugeBox: document.getElementById('gauge-box'),
      background: document.getElementById('background-window'),
      arrowBox: document.getElementById('arrow-box'),
      tiles: document.getElementsByClassName('arrow-tile'),
      progress: document.getElementById('progress-bar')
    },
    _state: {
      full: false,
      model: {}
    },
    speed: {
      stop: 0,
      slow: 1,
      middle: 4,
      fast: 8
    },
    framerate: 16,
    progressbar: {
      currentSprite: 0,
      passingWidth: 0,
      recentWidth: 0,
      countTime: 0,
      settings: {
        durationTime: 1500,
        easing: 'easeOutExpo',
        tileSize: {
          width: 100,
          heigth: 20
        }
      }
    },
    display: {
      opacity: 0,
      countTime: 0,
      settings: {
        durationTime: 200,
        easing: 'easeOutSine'
      }
    },
    easing: {
      easeOutSine: function(t, b, c, d) {
        return c * Math.sin(t / d * (Math.PI / 2)) + b;
      },
      easeOutExpo: function(t, b, c, d) {
        if (t === d) {
          return b + c;
        } else {
          return c * (-Math.pow(2, -10 * t / d) + 1) + b;
        }
      }
    },
    initProgressbar: function() {
      this.progressbar.countTime = 0;
      this.progressbar.passingWidth = 0;
      this.progressbar.recentWidth = 0;
      this.el.progress.style.width = '0%';
      return this.changeState({
        full: false
      });
    },
    initDisplay: function() {
      return this.display.countTime = 0;
    },
    progressbarUpdate: function() {},
    makeProgressbarUpdate: function() {
      var arrowboxStyle, duration, easing, frame, framerate, model, progressbar, progressbarStyle, settings, tileHeight, tileWidth, tiles, _genPosition, _renderRatio;
      model = this._state.model;
      framerate = this.framerate;
      progressbar = this.progressbar;
      settings = progressbar.settings;
      tileWidth = settings.tileSize.width;
      tileHeight = settings.tileSize.heigth;
      duration = settings.durationTime / framerate | 0;
      easing = this.easing[settings.easing];
      tiles = this.el.tiles;
      progressbarStyle = this.el.progress.style;
      arrowboxStyle = this.el.arrowBox.style;
      frame = 0;
      _renderRatio = (function(_this) {
        return function() {
          progressbar.countTime = 0;
          progressbar.recentWidth = model.progress * 100;
          progressbar.passingWidth = +progressbarStyle.width.replace('%', '');
          return _this.fire('ratiorendered', null);
        };
      })(this);
      _genPosition = function(current) {
        return "" + (current % 4 * -tileWidth) + "px " + ((current / 4 | 0) * -tileHeight) + "px";
      };
      return this.progressbarUpdate = (function(_this) {
        return function() {
          var v, _i, _len;
          if (++frame % 2 === 0) {
            for (_i = 0, _len = tiles.length; _i < _len; _i++) {
              v = tiles[_i];
              v.style.backgroundPosition = _genPosition(progressbar.currentSprite);
            }
            progressbar.currentSprite = ++progressbar.currentSprite % 28;
          }
          if (frame % 50 === 0) {
            if (model.canRenderRatio) {
              _renderRatio();
            }
            if (model.canQuit && progressbarStyle.width === '100%') {
              _this.changeState({
                full: true
              });
            }
          }
          if (progressbar.countTime <= duration) {
            progressbarStyle.width = easing(progressbar.countTime++, progressbar.passingWidth, progressbar.recentWidth - progressbar.passingWidth, duration) + '%';
          }
          frame %= 100;
          return arrowboxStyle.left = "" + (frame * _this.speed[model.flowSpeed] % 100 - 100) + "px";
        };
      })(this);
    },
    fadingUpdate: function() {},
    makeFadingUpdate: function() {
      var backgroundStyle, display, duration, easing, frame, framerate, gaugeboxStyle, model, settings;
      model = this._state.model;
      framerate = this.framerate;
      display = this.display;
      settings = display.settings;
      duration = settings.durationTime / framerate | 0;
      easing = this.easing[settings.easing];
      gaugeboxStyle = this.el.gaugeBox.style;
      backgroundStyle = this.el.background.style;
      frame = 0;
      this.makeFadingUpdate = (function(_this) {
        return function() {
          var currentOpacity, targetOpacity, type;
          type = model.fading;
          currentOpacity = display.opacity;
          switch (type) {
            case 'stop':
              return;
            case 'in':
              targetOpacity = 1;
              break;
            case 'out':
              targetOpacity = 0;
          }
          return _this.fadingUpdate = function() {
            display.opacity = easing(display.countTime, currentOpacity, targetOpacity - currentOpacity, duration);
            gaugeboxStyle.opacity = display.opacity * 0.5;
            backgroundStyle.opacity = display.opacity * 0.8;
            if (display.countTime >= duration) {
              display.opacity = targetOpacity;
              if (model.fading === 'out') {
                _this._displayChange('none');
              }
              _this.fire('fadeend');
              _this.initDisplay();
              return;
            }
            return display.countTime++;
          };
        };
      })(this);
      return this.makeFadingUpdate();
    },
    fadeInOut: function(statusObj) {
      if (statusObj.fading === 'in') {
        this._displayChange('block');
      }
      return this.makeFadingUpdate();
    },
    _displayChange: function(prop) {
      this.el.gaugeBox.style.display = this.el.background.style.display = prop;
      return this.fire('hide', null);
    }
  };
  makePublisher(progressbarView);
  return makeStateful(progressbarView);
});


},{}],7:[function(require,module,exports){
var publisher,
  __hasProp = {}.hasOwnProperty;

publisher = {
  _subscribers: {
    any: []
  },
  on: function(type, fn, context) {
    if (type == null) {
      type = 'any';
    }
    fn = typeof fn === 'function' ? fn : context[fn];
    if (this._subscribers[type] == null) {
      this._subscribers[type] = [];
    }
    return this._subscribers[type].push({
      fn: fn,
      context: context || this
    });
  },
  remove: function(type, fn, context) {
    return this.visitSubscribers('unsubseribe', type, fn, context);
  },
  fire: function(type, publication) {
    return this.visitSubscribers('publish', type, publication);
  },
  visitSubscribers: function(action, type, arg) {
    var e, i, max, pubtype, subscribers, _i;
    if (type == null) {
      type = 'any';
    }
    pubtype = type;
    subscribers = this._subscribers[pubtype];
    max = subscribers != null ? subscribers.length : 0;
    for (i = _i = 0; 0 <= max ? _i < max : _i > max; i = 0 <= max ? ++_i : --_i) {
      if (action === 'publish') {
        try {
          subscribers[i].fn.call(subscribers[i].context, arg);
        } catch (_error) {
          e = _error;
          try {
            new Error("Error in " + pubtype + " : e -> " + e);
          } catch (_error) {
            console.log("message -> " + e.message);
            console.log("stack -> " + e.stack);
            console.log("fileName -> " + (e.fileName || e.sourceURL));
            console.log("line -> " + (e.line || e.lineNumber));
          }
        }
      } else {
        if (subscribers[i].fn === arg && subscribers[i].context === context) {
          subscribers.splice(i, 1);
        }
      }
    }
  }
};

module.exports = function(o) {
  var k, v;
  for (k in publisher) {
    if (!__hasProp.call(publisher, k)) continue;
    v = publisher[k];
    if (typeof v === 'function') {
      o[k] = v;
    }
  }
  return o._subscribers = {
    any: []
  };
};


},{}],8:[function(require,module,exports){
var stateful,
  __hasProp = {}.hasOwnProperty;

stateful = {
  _state: {},
  changeState: function(statusObj) {
    return this._changeState(statusObj, false);
  },
  margeState: function(statusObj) {
    return this._changeState(statusObj, true);
  },
  getState: function(prop) {
    return this._state[prop];
  },
  _changeState: function(statusObj, marge) {
    var changeOwnProp, changed, margeProp, newStatus, state, status, type;
    state = this._state;
    changed = false;
    for (type in statusObj) {
      status = statusObj[type];
      changeOwnProp = state.hasOwnProperty(type) && state[type] !== status;
      margeProp = !state.hasOwnProperty(type) && marge;
      if (changeOwnProp || margeProp) {
        changed = true;
        state[type] = status;
        newStatus = {};
        newStatus[type] = status;
        this.fire("" + (type.toLowerCase()) + "change", newStatus);
      }
    }
    if (changed) {
      return this.fire("statechange", state);
    }
  }
};

module.exports = function(o) {
  var i, v;
  for (i in stateful) {
    if (!__hasProp.call(stateful, i)) continue;
    v = stateful[i];
    if (typeof v === 'function') {
      o[i] = v;
    }
  }
  return o._state = o._state || {};
};


},{}]},{},[3])