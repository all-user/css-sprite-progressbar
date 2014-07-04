/*
 *  publish.js and stateful.js are required for using this scripts.
 *
 * */

/*
 *  preloaer.js is required for using this scripts.
 *
 * */

var photosModel = {

  maxConcurrentRequest: 0,
  allRequestSize      : 0,
  loadedSize          : 0,
  photosURLArr        : [],
  unloadedURLArr      : [],
  photosArr           : [],

  _state: {
    validated: false,
    completed: false
  },

  clear: function () {
    this.changeState({
      completed: false,
      validated: false
    });
    this.setProperties({
      maxConcurrentRequest: 0,
      allRequestSize      : 0,
      loadedSize          : 0,
      photosURLArr        : [],
      unloadedURLArr      : [],
      photosArr           : [],
    });
    this.fire("clear", null);
  },

  incrementLoadedSize: function () {
    this.loadedSize++;
    this.fire("loadedincreased", photosModel.loadedSize);
    if (this.loadedSize === this.allRequestSize) {
      this.changeState({ completed: true });
    }
  },

  initPhotos: function (urlArr) {
    this.setProperties({
      photosURLArr: urlArr,
      allRequestSize: urlArr.length
    });
    this.validateProperties();
    this.loadPhotos();
  },

  loadPhotos: function () {
    this._load(this.maxConcurrentRequest);
  },

  loadNext: function () {
    this._load(1);
  },

  _load: function (size) {
    if (this.unloadedURLArr.length === 0) {
      return;
    }
    this.fire("delegateloading", this.unloadedURLArr.splice(0, size));
  },

  addPhoto: function (img) {
    this.photosArr.push(img);
    this.incrementLoadedSize();
  },

  setProperties: function (props) {
    var i;

    for (i in props) {
      if (props.hasOwnProperty(i) && this.hasOwnProperty(i)) {
        this[i] = props[i];
      }
    }
    this.changeState({ validated: false });
  },

  validateProperties: function () {
    try {
      this.maxConcurrentRequest = parseInt(this.maxConcurrentRequest, 10);
      this.allRequestSize       = parseInt(this.allRequestSize      , 10);

      this.maxConcurrentRequest = this.maxConcurrentRequest > this.allRequestSize ?
        this.allRequestSize :
        this.maxConcurrentRequest < 0 ?
          0 :
          this.maxConcurrentRequest;

      this.unloadedURLArr = this.photosURLArr.slice(0);

      this.changeState({ validated: true });
    }
    catch (e) {
      console.log("Validate Error : " + e);
    }
  },

  getNextPhoto: function (received) {
    return this._getPhotosArr(received, 1);
  },

  _getPhotosArr: function (received, length) {
    var sent = [],
        i, j, res, resLen;

    if        (typeof received === "undefined") {
      res = this.photosArr.slice(0, length);
      for (i = 0, resLen = res.length; i < resLen; i++) {
        res[i] = res[i].cloneNode();
        sent[i] = i;
      }

    } else if (typeof received === "number"   ) {
      i = received;
      res = [];
      res.push(this.photosArr[i].cloneNode());
      sent = [i];

    } else {
      res = [];

      for (i = j = 0; i < length; i++, j++) {
        while (received[j]) {
          j++;
        }
        if (typeof this.photosArr[j] === "undefined") {
          break;
        }
        res[i]  = this.photosArr[j].cloneNode();
        sent[i] = j;
      }

    }
    res.sent = sent;

    return res;
  }

};

makePublisher(photosModel);
makeStateful (photosModel);
