/*
 *  publish.js and stateful.js are required for using this scripts.
 *
 * */

var progressbarView;

document.addEventListener("DOMContentLoaded", function () {

  progressbarView = {

    el: {
      gaugeBox  : document.getElementById("gauge-box"),
      background: document.getElementById("background-window"),
      arrowBox  : document.getElementById("arrow-box"),
      tiles     : document.getElementsByClassName("arrow-tile"),
      progress  : document.getElementById("progress-bar")
    },

    _state: {
      full   : false,
      model  : {}
    },

    speed: {
      stop  : 0,
      slow  : 1,
      middle: 4,
      fast  : 8
    },

    framerate: 16,

    progressbar: {
      currentSprite: 0,
      passingWidth : 0,
      recentWidth  : 0,
      countTime    : 0,
      settings     : {
        durationTime: 1500,
        easing      : "easeOutExpo",
        tileSize    : {
          width  : 100,
          height : 20
        }
      }
    },

    display: {
      opacity  : 0,
      countTime: 0,
      settings : {
        durationTime: 200,
        easing      : "easeOutSine"
      }
    },

    easing: {
      easeOutSine: function (t, b, c, d) {
        return c * Math.sin(t/d * (Math.PI/2)) + b;
      },
      easeOutExpo: function (t, b, c, d) {
        return (t==d) ? b+c : c * (-Math.pow(2, -10 * t/d) + 1) + b;
      }
    },

    initProgressbar: function () {
      this.progressbar.countTime    = 0;
      this.progressbar.passingWidth = 0;
      this.progressbar.recentWidth  = 0;
      this.el.progress.style.width  = "0%";
      this.changeState({ full: false });
    },

    initDisplay: function () {
      this.display.countTime = 0;
    },

    progressbarUpdate: function () {},

    makeProgressbarUpdate: function () {
      var _this            = this,
          model            = _this._state.model,
          framerate        = _this.framerate,
          progressbar      = _this.progressbar,
          settings         = progressbar.settings,
          tileWidth        = settings.tileSize.width,
          tileHeight       = settings.tileSize.height,
          duration         = settings.durationTime / framerate | 0,
          easing           = _this.easing[settings.easing],
          tiles            = _this.el.tiles,
          progressbarStyle = _this.el.progress.style,
          arrowboxStyle    = _this.el.arrowBox.style,
          frame            = 0,
          fn;

      fn = function () {

        if (++frame % 2 === 0) {

          for (var i = 0; i < tiles.length; i++) {
            tiles[i].style.backgroundPosition = _genPosition(progressbar.currentSprite);
          }
          progressbar.currentSprite = ++progressbar.currentSprite % 28;

        }

        if (frame % 50 === 0) {
          if (model.canRenderRatio) {
            _renderRatio();
          }
          if (model.canQuit && progressbarStyle.width === "100%") {
            _this.changeState({ full: true });
          }
        }

        if (progressbar.countTime <= duration) {
          progressbarStyle.width = easing(progressbar.countTime++, progressbar.passingWidth, progressbar.recentWidth - progressbar.passingWidth, duration) + "%";
        }
        frame %= 100;
        arrowboxStyle.left = -100 + (frame * _this.speed[model.flowSpeed] % 100) + "px";

      };

      _this.progressbarUpdate = fn;
      return fn;

      function _renderRatio() {
        progressbar.countTime    = 0;
        progressbar.recentWidth  = model.progress * 100;
        progressbar.passingWidth = progressbarStyle.width.replace("%", "") * 1;
        _this.fire("ratiorendered", null);
      }

      function _genPosition(current) {
         return current % 4 * -tileWidth + "px " + (current / 4 | 0) * -tileHeight + "px";
      }

    },

    fadingUpdate: function () {},

    makeFadingUpdate: function () {

      var _this           = this,
          model           = _this._state.model,
          framerate       = _this.framerate,
          display         = _this.display,
          settings        = display.settings,
          duration        = settings.durationTime / framerate | 0,
          easing          = _this.easing[settings.easing],
          gaugeboxStyle   = _this.el.gaugeBox.style,
          backgroundStyle = _this.el.background.style,
          frame           = 0,
          fn;

      fn = function () {
        var type           = model.fading,
            currentOpacity = display.opacity,
            targetOpacity;

        if        (type === "stop") {
          return;
        } else if (type === "in"  ) {
          targetOpacity = 1;
        } else if (type === "out" ) {
          targetOpacity = 0;
        }

        fn = function () {
          display.opacity = easing(display.countTime, currentOpacity, targetOpacity - currentOpacity, duration);

          gaugeboxStyle  .opacity = display.opacity * 0.5;
          backgroundStyle.opacity = display.opacity * 0.8;

          if (display.countTime >= duration) {
            display.opacity = targetOpacity;
            if (model.fading === "out") {
              _this._displayChange("none");
            }
            _this.fire("fadeend");
            _this.initDisplay();
            return;
          }
          display.countTime++;
        };

        _this.fadingUpdate = fn;
        return fn;
      };

      _this.makeFadingUpdate = fn;
      return _this.makeFadingUpdate();

    },

    fadeInOut: function (statusObj) {
      if (statusObj.fading === "in") {
        this._displayChange("block");
      }
      this.makeFadingUpdate();
    },

    _displayChange: function (prop) {
      this.el.gaugeBox.style.display = this.el.background.style.display = prop;
      this.fire("hide", null);
    },

  };

  makePublisher(progressbarView);
  makeStateful (progressbarView);

});
