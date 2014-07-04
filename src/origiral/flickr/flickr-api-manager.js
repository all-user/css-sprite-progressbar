/*
 *  publish.js and stateful.js are required for using this scripts.
 *
 * */

// global function for wait and fire api response
jsonFlickrApi = function (json) {
  jsonFlickrApi.fire("apiresponse", json);
};


// Model for Flickr API access and management

var flickrApiManager = {

  apiOptions: {
    apiKey        : "a3d606b00e317c733132293e31e95b2e",
    format        : "json",
    noJsonCallback: false,
    others        : {
      text    : "",
      sort    : "date-posted-desc",
      per_page: 0
    }
  },

  _state: {
    waiting: false
  },

  setAPIOptions: function (options) {
    var i;

    for (i in options) {
      if (options.hasOwnProperty(i)) {

        this.apiOptions.hasOwnProperty(i) ?
          this.apiOptions[i]        = options[i]:
          this.apiOptions.others[i] = options[i];

      }
    }
  },

  validateOptions: function () {
    try {
      if (parseInt(this.apiOptions.others.per_page, 10) < 0) {
        this.apiOptions.others.per_page = 0;
      }
    }
    catch (e) {
      console.log("Error : " + e);
    }
  },

  sendRequestJSONP: function (options) {
    if (this._state.waiting) {
      return false;
    }
    this.changeState({ "waiting": true });

    var newScript = document.createElement("script"),
        oldScript = document.getElementById("kick-api");

    if (options) {
      this.setAPIOptions(options);
    }
    this.validateOptions();

    newScript.id  = "kick-api";
    newScript.src = this.genURI(this.apiOptions);

    if (oldScript) {
      document.body.replaceChild(newScript, oldScript);
    } else {
      document.body.appendChild (newScript);
    }
    this.fire("sendrequest", null);
  },

  genURI: function (options) {
    var apiKey = options.apiKey,
        others = options.others,
        uri    = "",
        i;

    uri = "api_key=" + apiKey;
    for (i in others) {
      if (others.hasOwnProperty(i)) {
        uri += "&" + i + "=" + others[i];
      }
    }
    uri += "&format=" + options.format;
    // JSON or JSONP
    if (options.format === "json" && options.noJsonCallback) {
      uri += "&nojsoncallback=1";
    }
    return "http://api.flickr.com/services/rest/?method=flickr.photos.search&" + uri;
  },

  genPhotosURLArr: function (json) {
    var urlArr      = [],
        apiPhotoArr = json.photos.photo;

    for (var i = 0; i < apiPhotoArr.length; i++) {
      urlArr[i] = "http://farm" + apiPhotoArr[i].farm + ".staticflickr.com/" + apiPhotoArr[i].server + "/" + apiPhotoArr[i].id + "_" + apiPhotoArr[i].secret + ".jpg";
    }

    return urlArr;
  },

  handleAPIResponse: function (json) {
    this.changeState({ "waiting": false });
    this.fire("apiresponse", json                      );
    this.fire("urlready"   , this.genPhotosURLArr(json));
  }

};

makePublisher(jsonFlickrApi);
makePublisher(flickrApiManager);
makeStateful (flickrApiManager);
jsonFlickrApi.on("apiresponse", "handleAPIResponse", flickrApiManager);
