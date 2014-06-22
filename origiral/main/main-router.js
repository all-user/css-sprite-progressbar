document.addEventListener("DOMContentLoaded", function () {

  var mediator = {

    store: {},

    // progressbarModel
    setDenomiPhotosLength: function (urlArr) {
      progressbarModel.setDenominator(urlArr.length);
    },

    checkCanQuit: function () {
      var bool = !flickrApiManager.getState("waiting") && photosModel.getState("completed");
      progressbarModel.changeState({ canQuit: bool });
    },

    decideFlowSpeed: function () {
      var speed;
      if        (progressbarView.getState("full")) {
        speed = "fast";

      } else if (flickrApiManager.getState("waiting")) {
        speed = "slow";

      } else {
        speed = "middle";
      }
      progressbarModel.setFlowSpeed(speed);
    },

    // renderer
    handleFading: function (statusObj) {
      var action = statusObj.fading;

      if (action === "stop") {
        renderer.deleteUpdater(this.store.fadingUpdater);
      } else {
        this.store.fadingUpdater = progressbarView.fadingUpdate.bind(progressbarView);
        renderer.addUpdater(this.store.fadingUpdater);
      }

    },

    // any observe inputView
    handleButtonClick: function () {
      progressbarModel.run();
      photosModel.clear();
      flickrApiManager.setAPIOptions(inputView.getOptions());
      photosModel.setProperties({ maxConcurrentRequest: inputView.getMaxConcurrentRequest() });
      flickrApiManager.sendRequestJSONP();
    }


  };
  // inputView
  inputView.el.searchButton.addEventListener("click", inputView.handleClick.bind(inputView));

  // photosModel
  flickrApiManager.on("urlready"       , "initPhotos"           , photosModel     );

  // progressbarModel
  flickrApiManager.on("urlready"       , "setDenomiPhotosLength", mediator        );
  photosModel     .on("loadedincreased", "setNumerator"         , progressbarModel);
  flickrApiManager.on("waitingchange"  , "checkCanQuit"         , mediator        );
  photosModel     .on("completedchange", "checkCanQuit"         , mediator        );
  flickrApiManager.on("waitingchange"  , "decideFlowSpeed"       , mediator        );
  photosModel     .on("clear"          , "clear"                , progressbarModel);
  progressbarView .on("fullchange"     , "decideFlowSpeed"       , mediator        );

  // renderer
  progressbarModel.on("fadingchange"   , "handleFading"         , mediator        );
  progressbarModel.on("run"            , "draw"                 , renderer        );
  progressbarModel.on("stop"           , "pause"                , renderer        );

  // any observe inputView
  inputView       .on("searchclick"    , "handleButtonClick"    , mediator        );

});
