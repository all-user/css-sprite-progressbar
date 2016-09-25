(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
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
    newScript.onerror = (function(_this) {
      return function(e) {
        _this._state.waiting = false;
        return _this.fire("apirequestfailed", e);
      };
    })(this);
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
    if (this.getState('waiting')) {
      this.changeState({
        'waiting': false
      });
      this.fire('apiresponse', json);
      return this.fire('urlready', this.genPhotosURLArr(json));
    }
  }
};

makePublisher(jsonFlickrApi);

makePublisher(flickrApiManager);

makeStateful(flickrApiManager);

jsonFlickrApi.on('apiresponse', 'handleAPIResponse', flickrApiManager);

module.exports = flickrApiManager;

},{"../util/publisher":15,"../util/stateful":16}],2:[function(require,module,exports){
var inputView, makePublisher, makeStateful,
  __hasProp = {}.hasOwnProperty;

makePublisher = require('../util/publisher');

makeStateful = require('../util/stateful');

inputView = {
  el: {
    searchText: document.getElementById('search-text'),
    perPage: document.getElementById('per-page'),
    maxReq: document.getElementById('max-req'),
    searchButton: document.getElementById('search-button'),
    canselButton: document.getElementById('cansel-button'),
    photosView: document.getElementById('photos-view'),
    inputWindow: document.getElementById('input-window')
  },
  _state: {
    searchText: '',
    perPage: '',
    maxReq: ''
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
    return this.fire('canselclick', e);
  },
  handleInputKeyup: function(e) {
    var id, newValue, oldValue;
    if (!'INPUT') {
      if (e.target.tagName) {
        return;
      }
    }
    id = e.target.id.replace(/(\w+)-(\w+)/, function(match, p1, p2) {
      return "" + p1 + (p2[0].toUpperCase()) + (p2.substr(1));
    });
    oldValue = this._state[id];
    newValue = e.target.value;
    if (newValue !== oldValue) {
      return this.changeState(id, newValue);
    }
  }
};

makePublisher(inputView);

makeStateful(inputView);

inputView.el.searchButton.addEventListener('click', inputView.handleClick.bind(inputView));

inputView.el.canselButton.addEventListener('click', inputView.handleCansel.bind(inputView));

inputView.el.inputWindow.addEventListener('keyup', inputView.handleInputKeyup.bind(inputView));

inputView.changeState({
  searchText: inputView.el.searchText.value,
  perPage: inputView.el.perPage.value,
  maxReq: inputView.el.maxReq.value
});

module.exports = inputView;

},{"../util/publisher":15,"../util/stateful":16}],3:[function(require,module,exports){
var flickrApiManager, photosModel;

window.ltWatch = require('../util/ltWatch');

flickrApiManager = require('../flickr/flickr-api-manager');

photosModel = require('../photos/photos-model');

document.addEventListener('DOMContentLoaded', function() {
  var inputView, mediator, progressbarModel, progressbarView, renderer;
  inputView = require('../input/input-view');
  require('../photos/photos-router');
  progressbarModel = require('../progressbar/progressbar-model');
  progressbarView = require('../progressbar/progressbar-view');
  require('../progressbar/progressbar-router');
  renderer = require('../renderer/renderer');
  require('../renderer/renderer-router');
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
      progressbarModel.resque();
      flickrApiManager.setAPIOptions(inputView.getOptions());
      photosModel.setProperties({
        maxConcurrentRequest: inputView.getMaxConcurrentRequest()
      });
      return flickrApiManager.sendRequestJSONP();
    },
    handleCanselClick: function() {
      photosModel.clearUnloaded();
      if (flickrApiManager.getState('waiting')) {
        flickrApiManager.changeState({
          'waiting': false
        });
        progressbarModel.fadeOut();
      }
      if (progressbarModel.getState("failed")) {
        return progressbarModel.fadeOut();
      }
    }
  };
  flickrApiManager.on('urlready', 'initPhotos', photosModel);
  inputView.on('canselclick', 'handleCanselClick', mediator);
  flickrApiManager.on("apirequestfailed", "failed", progressbarModel);
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

},{"../flickr/flickr-api-manager":1,"../input/input-view":2,"../photos/photos-model":4,"../photos/photos-router":5,"../progressbar/progressbar-model":8,"../progressbar/progressbar-router":9,"../progressbar/progressbar-view":10,"../renderer/renderer":12,"../renderer/renderer-router":11,"../util/ltWatch":14}],4:[function(require,module,exports){
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
      unloadedURLArr: [],
      allRequestSize: this.loadedSize
    });
    return this.fire('clearunloaded', this.loadedSize);
  },
  incrementLoadedSize: function() {
    this.loadedSize++;
    this.fire('loadedincreased', photosModel.loadedSize);
    if (this.loadedSize >= this.allRequestSize) {
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

},{"../util/publisher":15,"../util/stateful":16}],5:[function(require,module,exports){
var mediator, photosModel, photosView, preloader;

photosModel = require('./photos-model');

photosView = require('./photos-view');

preloader = require('./preloader');

mediator = {
  appendNextPhoto: function() {
    var photos;
    photos = photosModel.getNextPhoto(photosView.getAppended());
    photos[0].className = 'flickr-img';
    return photosView.appendPhotos(photos);
  }
};

photosModel.on('delegateloading', 'preload', preloader);

photosModel.on('loadedincreased', 'loadNext', photosModel);

preloader.on('loaded', 'addPhoto', photosModel);

photosModel.on('loadedincreased', 'appendNextPhoto', mediator);

photosModel.on('clear', 'clear', photosView);

},{"./photos-model":4,"./photos-view":6,"./preloader":7}],6:[function(require,module,exports){
module.exports = {
  el: {
    photosView: document.getElementById('photos-view')
  },
  appended: [],
  getAppended: function() {
    return this.appended;
  },
  appendPhotos: function(imgArr) {
    var frag, i, sent, v, _i, _len;
    if (imgArr == null) {
      return;
    }
    if (imgArr.length === 0) {
      return;
    }
    frag = document.createDocumentFragment();
    sent = imgArr.sent;
    for (i = _i = 0, _len = imgArr.length; _i < _len; i = ++_i) {
      v = imgArr[i];
      this.appended[sent[i]] = true;
      frag.appendChild(v);
    }
    return this.el.photosView.appendChild(frag);
  },
  clear: function() {
    var view;
    view = this.el.photosView;
    while (view.firstChild) {
      view.firstChild.onload = null;
      view.removeChild(view.firstChild);
    }
    return this.appended = [];
  }
};

},{}],7:[function(require,module,exports){
var makePublisher, objfield, preloader;

makePublisher = require('../util/publisher');

objfield = document.createElement('div');

objfield.style.width = '0px';

objfield.style.height = '0px';

objfield.style.visibility = 'hidden';

objfield.id = 'objfield';

document.body.appendChild(objfield);

preloader = {
  preload: function(urlArr) {
    var body, fragment, i, obj, v, _i, _len;
    fragment = document.createDocumentFragment();
    body = document.body;
    for (i = _i = 0, _len = urlArr.length; _i < _len; i = ++_i) {
      v = urlArr[i];
      obj = document.createElement('object');
      obj.width = 0;
      obj.height = 0;
      obj.data = v;
      obj.onload = this.makeCreatePhoto(v);
      fragment.appendChild(obj);
    }
    return objfield.appendChild(fragment);
  },
  createPhoto: function() {},
  makeCreatePhoto: function(url) {
    return (function(_this) {
      return function() {
        var img;
        img = document.createElement('img');
        img.src = url;
        return _this.fire('loaded', img);
      };
    })(this);
  }
};

makePublisher(preloader);

module.exports = preloader;

},{"../util/publisher":15}],8:[function(require,module,exports){
var makePublisher, makeStateful, progressbarModel;

makePublisher = require('../util/publisher');

makeStateful = require('../util/stateful');

progressbarModel = {
  _state: {
    hidden: true,
    fading: 'stop',
    failed: false,
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
  failed: function() {
    return this.changeState({
      failed: true
    });
  },
  resque: function() {
    return this.changeState({
      failed: false
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
      res = Math[this.processType[process]](res);
    }
    return res;
  }
};

makePublisher(progressbarModel);

makeStateful(progressbarModel);

module.exports = progressbarModel;

},{"../util/publisher":15,"../util/stateful":16}],9:[function(require,module,exports){
var mediator, progressbarModel, progressbarView, renderer;

progressbarModel = require('./progressbar-model');

progressbarView = require('./progressbar-view');

renderer = require("./../renderer/renderer");

mediator = {
  handleRendered: function() {
    return progressbarModel.changeState({
      canRenderRatio: false
    });
  },
  handleFull: function(statusObj) {
    if (statusObj.full) {
      return progressbarModel.fadeOut();
    }
  },
  handleHide: function() {
    progressbarModel.changeState({
      hidden: true
    });
    progressbarModel.resque();
    return progressbarModel.stop();
  },
  handleFailedChange: function() {
    if (progressbarModel.getState("failed")) {
      progressbarView.el.arrowBox.style.display = progressbarView.el.progress.style.display = "none";
      return progressbarView.showFailedMsg();
    } else {
      progressbarView.el.arrowBox.style.display = progressbarView.el.progress.style.display = "block";
      return progressbarView.hideFailedMsg();
    }
  }
};

progressbarModel.on('run', 'fadeIn', progressbarModel);

progressbarView.on('ratiorendered', 'handleRendered', mediator);

progressbarView.on('fullchange', 'handleFull', mediator);

progressbarView.on('fadeend', 'fadeStop', progressbarModel);

progressbarView.on('hide', 'handleHide', mediator);

progressbarView.changeState({
  model: progressbarModel._state
});

progressbarModel.on('fadingchange', 'fadeInOut', progressbarView);

progressbarModel.on("failedchange", "handleFailedChange", mediator);

progressbarView.on('hide', 'initProgressbar', progressbarView);

},{"./../renderer/renderer":12,"./progressbar-model":8,"./progressbar-view":10}],10:[function(require,module,exports){
var DHTMLSprite, makePublisher, makeStateful, progressbarView;

makePublisher = require('../util/publisher');

makeStateful = require('../util/stateful');

DHTMLSprite = require('../util/DHTMLSprite');

progressbarView = {
  el: {
    gaugeBox: document.getElementById('gauge-box'),
    background: document.getElementById('background-window'),
    arrowBox: document.getElementById('arrow-box'),
    progress: document.getElementById('progress-bar'),
    failedMsg: document.getElementById('failed-msg')
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
  globalFPS: null,
  progressbar: {
    passingWidth: 0,
    recentWidth: 0,
    countTime: 0,
    settings: {
      durationTime: 1200,
      easing: 'easeOutExpo',
      targetFPS: {
        tile: 20,
        slide: 30,
        ratio: 1.2
      },
      resolutionFPS: null
    }
  },
  display: {
    opacity: 0,
    countTime: 0,
    settings: {
      durationTime: 500,
      easing: 'easeOutSine',
      resolutionFPS: null
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
  setGlobalFPS: function(FPS) {
    return this.globalFPS = FPS;
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
  spriteTile: function(options) {
    var index, sprite, x, y;
    x = options.x, y = options.y;
    index = 0;
    sprite = DHTMLSprite(options);
    sprite.draw(x, y);
    sprite.update = function(tCoeff) {
      index += tCoeff;
      index %= 28;
      return sprite.changeImage(index | 0);
    };
    return sprite;
  },
  progressbarUpdate: function() {},
  makeProgressbarUpdate: function() {
    var arrowboxStyle, duration, easing, model, progressbar, progressbarStyle, ratioCoeff, resolutionFramerate, settings, slideCoeff, slideCounter, tileCoeff, tiles, updateCounter, _renderRatio, _throttle;
    if (this.globalFPS === null) {
      throw new Error('Must define globalFPS.');
    }
    model = this._state.model;
    progressbar = this.progressbar;
    settings = progressbar.settings;
    duration = settings.durationTime / (1000 / this.globalFPS);
    easing = this.easing[settings.easing];
    tiles = [0, 100, 200, 300, 400, 500].map((function(_this) {
      return function(pos) {
        return _this.spriteTile({
          x: pos,
          y: 0,
          width: 100,
          height: 20,
          imagesWidth: 400,
          drawTarget: _this.el.arrowBox,
          images: './images/arrow.png'
        });
      };
    })(this));
    progressbarStyle = this.el.progress.style;
    arrowboxStyle = this.el.arrowBox.style;
    tileCoeff = settings.targetFPS.tile / this.globalFPS;
    slideCoeff = settings.targetFPS.slide / this.globalFPS;
    ratioCoeff = settings.targetFPS.ratio / this.globalFPS;
    updateCounter = 0;
    slideCounter = 0;
    _renderRatio = (function(_this) {
      return function() {
        progressbar.countTime = 0;
        progressbar.recentWidth = model.progress * 100;
        progressbar.passingWidth = +progressbarStyle.width.replace('%', '');
        return _this.fire('ratiorendered', null);
      };
    })(this);
    _throttle = settings.resolutionFPS === null ? function(countTime) {
      return countTime;
    } : (resolutionFramerate = this.globalFPS / settings.resolutionFPS, function(countTime) {
      return countTime - (countTime % resolutionFramerate);
    });
    return this.progressbarUpdate = (function(_this) {
      return function(tCoeff) {
        var tile, _i, _len, _tileCoeff;
        _tileCoeff = tCoeff * tileCoeff;
        for (_i = 0, _len = tiles.length; _i < _len; _i++) {
          tile = tiles[_i];
          tile.update(_tileCoeff);
        }
        updateCounter += tCoeff * ratioCoeff;
        if (updateCounter > 1) {
          if (model.canRenderRatio) {
            _renderRatio();
          }
          if (model.canQuit && (+progressbarStyle.width.replace('%', '')) >= 99.9) {
            _this.changeState({
              full: true
            });
          }
        }
        if (progressbar.countTime <= duration) {
          progressbar.countTime += tCoeff;
          progressbarStyle.width = easing(_throttle(progressbar.countTime), progressbar.passingWidth, progressbar.recentWidth - progressbar.passingWidth, duration) + '%';
        }
        slideCounter += tCoeff * slideCoeff;
        arrowboxStyle.left = "" + (slideCounter * _this.speed[model.flowSpeed] % 100 - 100) + "px";
        return updateCounter %= 1;
      };
    })(this);
  },
  fadingUpdate: function() {},
  makeFadingUpdate: function() {
    var backgroundStyle, display, duration, easing, gaugeboxStyle, model, resolutionFramerate, settings, _throttle;
    model = this._state.model;
    display = this.display;
    settings = display.settings;
    duration = settings.durationTime / (1000 / this.globalFPS);
    easing = this.easing[settings.easing];
    gaugeboxStyle = this.el.gaugeBox.style;
    backgroundStyle = this.el.background.style;
    _throttle = settings.resolutionFPS === null ? function(countTime) {
      return countTime;
    } : (resolutionFramerate = this.globalFPS / settings.resolutionFPS, function(countTime) {
      return countTime - (countTime % resolutionFramerate);
    });
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
        return _this.fadingUpdate = function(tCoeff) {
          display.opacity = easing(_throttle(display.countTime), currentOpacity, targetOpacity - currentOpacity, duration);
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
          return display.countTime += tCoeff;
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
  showFailedMsg: function() {
    return this.el.failedMsg.style.display = "block";
  },
  hideFailedMsg: function() {
    return this.el.failedMsg.style.display = "none";
  },
  _displayChange: function(prop) {
    this.el.gaugeBox.style.display = this.el.background.style.display = prop;
    if (prop === "none") {
      return this.fire('hide', null);
    }
  }
};

makePublisher(progressbarView);

makeStateful(progressbarView);

module.exports = progressbarView;

},{"../util/DHTMLSprite":13,"../util/publisher":15,"../util/stateful":16}],11:[function(require,module,exports){
var progressbarView, renderer;

renderer = require('./renderer');

progressbarView = require('../progressbar/progressbar-view');

progressbarView.setGlobalFPS(renderer.targetFPS);

renderer.addUpdater(progressbarView.makeProgressbarUpdate());

},{"../progressbar/progressbar-view":10,"./renderer":12}],12:[function(require,module,exports){
var makePublisher, makeStateful, renderer, timeInfo;

makePublisher = require('../util/publisher');

makeStateful = require('../util/stateful');

timeInfo = require('../util/timeInfo');

renderer = {
  updaters: [],
  framerate: 16,
  targetFPS: 60,
  timerID: null,
  _state: {
    running: false,
    deleted: false
  },
  addUpdater: function(updater) {
    if (updater instanceof Array) {
      return this.updaters.concat(updater);
    } else if (typeof updater === 'function') {
      return this.updaters.push(updater);
    }
  },
  deleteUpdater: function(updater) {
    return this._visitUpdaters('delete', updater);
  },
  _visitUpdaters: function(action, fn) {
    var i, updaters, v, _i, _len, _results;
    updaters = this.updaters;
    if (action === 'delete') {
      _results = [];
      for (i = _i = 0, _len = updaters.length; _i < _len; i = ++_i) {
        v = updaters[i];
        if (v === fn) {
          updaters[i] = null;
          _results.push(this.changeState({
            deleted: true
          }));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    }
  },
  draw: function() {},
  pause: function() {
    clearInterval(this.timerID);
    return this.changeState({
      running: false
    });
  },
  makeDraw: function() {
    var updaters;
    updaters = this.updaters;
    return this.draw = (function(_this) {
      return function() {
        var coeffTimer;
        if (_this._state.running) {
          return;
        }
        coeffTimer = timeInfo(_this.targetFPS);
        _this.changeState({
          running: true
        });
        return _this.timerID = setInterval(function() {
          var e, i, info, v, _i, _len;
          info = coeffTimer.getInfo();
          for (i = _i = 0, _len = updaters.length; _i < _len; i = ++_i) {
            v = updaters[i];
            try {
              v(info.coefficient);
            } catch (_error) {
              e = _error;
              try {
                new Error("Error in draw : e -> " + e);
              } catch (_error) {
                console.log("message -> " + e.message);
                console.log("stack -> " + e.stack);
                console.log("fileName -> " + (e.fileName || e.sourceURL));
                console.log("line -> " + (e.line || e.lineNumber));
              }
            }
          }
          if (_this._state.deleted) {
            i = 0;
            while (i !== updaters.length) {
              if (updaters[i] === null) {
                updaters.splice(i, 1);
              } else {
                i++;
              }
            }
            return _this.changeState({
              deleted: false
            });
          }
        }, _this.framerate);
      };
    })(this);
  }
};

renderer.makeDraw();

makePublisher(renderer);

makeStateful(renderer);

module.exports = renderer;

},{"../util/publisher":15,"../util/stateful":16,"../util/timeInfo":17}],13:[function(require,module,exports){
var DHTMLSprite;

DHTMLSprite = function(options) {
  var eleStyle, element, height, imagesWidth, sprite, width;
  width = options.width, height = options.height, imagesWidth = options.imagesWidth;
  element = document.createElement('div');
  options.drawTarget.appendChild(element);
  eleStyle = element.style;
  element.style.position = 'absolute';
  element.style.width = "" + width + "px";
  element.style.height = "" + height + "px";
  element.style.backgroundImage = "url(" + options.images + ")";
  return sprite = {
    draw: function(x, y) {
      eleStyle.left = "" + x + "px";
      return eleStyle.top = "" + y + "px";
    },
    changeImage: function(index) {
      var hOffset, vOffset;
      index *= width;
      vOffset = -(index / imagesWidth | 0) * height;
      hOffset = -index % imagesWidth;
      return eleStyle.backgroundPosition = "" + hOffset + "px " + vOffset + "px";
    },
    show: function() {
      return eleStyle.display = 'block';
    },
    hide: function() {
      return eleStyle.display = 'none';
    },
    destroy: function() {
      return eleStyle.remove();
    }
  };
};

module.exports = DHTMLSprite;

},{}],14:[function(require,module,exports){
window.ltWatch = function(arg) {
  return arg;
};

module.exports = ltWatch;

},{}],15:[function(require,module,exports){
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
          console.log("" + type + " is fire");
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

},{}],16:[function(require,module,exports){
var stateful,
  __hasProp = {}.hasOwnProperty;

stateful = {
  _state: {},
  changeState: function(prop, value) {
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

},{}],17:[function(require,module,exports){
var timeInfo;

timeInfo = function(goalFPS) {
  var interCount, oldTime, paused, totalCoefficient, totalFPS;
  oldTime = 0;
  paused = true;
  interCount = 0;
  totalFPS = 0;
  totalCoefficient = 0;
  return {
    getInfo: function() {
      var FPS, coefficient, elapsed, newTime;
      if (paused === true) {
        paused = false;
        oldTime = Date.now();
        return {
          elapsed: 0,
          coefficient: 0,
          FPS: 0,
          averageFPS: 0,
          averageCoefficient: 0
        };
      }
      newTime = Date.now();
      elapsed = newTime - oldTime;
      oldTime = newTime;
      FPS = 1000 / elapsed;
      interCount++;
      totalFPS += FPS;
      coefficient = goalFPS / FPS;
      totalCoefficient += coefficient;
      return {
        elapsed: elapsed,
        coefficient: coefficient,
        FPS: FPS,
        averageFPS: totalFPS / interCount,
        averageCoefficient: totalCoefficient / interCount
      };
    },
    pause: function() {
      return paused = true;
    }
  };
};

module.exports = timeInfo;

},{}]},{},[3]);
