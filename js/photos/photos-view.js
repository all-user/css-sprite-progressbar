var photosView;

document.addEventListener("DOMContentLoaded", function () {

  photosView = {

    el: {
      photosView: document.getElementById("photos-view")
    },

    appended: [],

    getAppended: function () {
      return this.appended;
    },

    appendPhotos: function (imgArr) {
      if (typeof imgArr === "undefined" || imgArr.length === 0) {
        return;
      }
      var frag = document.createDocumentFragment(),
          sent = imgArr.sent,
          len  = imgArr.length,
          i;

      for (i = 0; i < len; i++) {
        this.appended[sent[i]] = true;
        frag.appendChild(imgArr[i]);
      }

      this.el.photosView.appendChild(frag);
    },

    clear: function () {
      var view = this.el.photosView;
      while (view.firstChild) {
        view.firstChild.onload = null;
        view.removeChild(view.firstChild);
      }
      this.appended = [];
    }

  };

});
