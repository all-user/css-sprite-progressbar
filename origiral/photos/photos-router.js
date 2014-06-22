document.addEventListener("DOMContentLoaded", function () {

  var mediator = {
    // photosView

    appendNextPhoto: function () {
      var photos = photosModel.getNextPhoto(
        photosView.getAppended()
      );
      photos[0].className = "flickr-img";
      photosView.appendPhotos(photos);
    },

  };
  // preloader
  photosModel.on("delegateloading", "preload"        , preloader  );

  // photosModel
  photosModel.on("loadedincreased", "loadNext"       , photosModel);
  preloader  .on("loaded"         , "addPhoto"       , photosModel);

  // photosView
  photosModel.on("loadedincreased", "appendNextPhoto", mediator   );
  photosModel.on("clear"          , "clear"          , photosView );

});
