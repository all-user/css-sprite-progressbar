document.addEventListener("DOMContentLoaded", function () {
  var mediator = {

    handleRendered: function () {
      progressbarModel.changeState({ canRenderRatio: false });
    },

    handleFull: function (statusObj) {
      if (statusObj.full) {
        progressbarModel.fadeOut();
      }
    },

    handleHide: function () {
      progressbarModel.changeState({ hidden: true });
      progressbarModel.stop();
    },

  };

  //progressbarModel
  progressbarModel.on("run"             , "fadeIn"                   , progressbarModel);
  progressbarView .on("ratiorendered"   , "handleRendered"           , mediator          );
  progressbarView .on("fullchange"      , "handleFull"               , mediator          );
  progressbarView .on("fadeend"         , "fadeStop"                 , progressbarModel);
  progressbarView .on("hide"            , "handleHide"               , mediator          );

  // progressbarView
  progressbarView.changeState({ model: progressbarModel._state });
  progressbarModel.on("fadingchange"    , "fadeInOut"                , progressbarView );
  progressbarView .on("hide"            , "initProgressbar"          , progressbarView );
});
