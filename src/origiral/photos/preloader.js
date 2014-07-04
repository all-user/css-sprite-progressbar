/*
 *  publish.js is required for using this scripts.
 *
 * */

var preloader;

document.addEventListener("DOMContentLoaded", function () {

  var objfield = document.createElement("div");
  objfield.style.width = "0px";
  objfield.style.height = "0px";
  objfield.style.visibility = "hidden";
  objfield.id = "objfield";
  document.body.appendChild(objfield);

  preloader = {

    preload: function (urlArr) {
      var obj,
          flagment = document.createDocumentFragment(),
          body = document.body,
          bindIndex = this.bindIndex,
          len = urlArr.length,
          i;
      for (i = 0; i < len; i++) {
        obj = document.createElement("object");
        obj.width = 0;
        obj.height = 0;
        obj.data = urlArr[i];
        obj.onload = this.makeCreatePhoto(urlArr[i]);
        flagment.appendChild(obj);
      }
      objfield.appendChild(flagment);
    },

    createPhoto: function () {},

    makeCreatePhoto: function (url) {
      var createPhoto = function () {
        var img;
        img =  document.createElement("img");
        img.src = url;
        this.fire("loaded", img);
      };
      return createPhoto.bind(this);
    },

  };

  makePublisher(preloader);
});
