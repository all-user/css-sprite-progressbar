progressbarModel = require './progressbar-model'
progressbarView = require './progressbar-view'
renderer = require "./../renderer/renderer"

mediator =
  handleRendered : ->
    progressbarModel.changeState(canRenderRatio : no)

  handleFull : (statusObj) ->
    progressbarModel.fadeOut() if statusObj.full

  handleHide : ->
    progressbarModel.changeState
      hidden : yes
    progressbarModel.resque()
    progressbarModel.stop()

  handleFailedChange: ->
    if progressbarModel.getState("failed")
      progressbarView.el.arrowBox.style.display =
      progressbarView.el.progress.style.display = "none"
      renderer.deleteUpdater progressbarView.progressbarUpdate
      progressbarView.showFailedMsg()
    else
      progressbarView.el.arrowBox.style.display =
      progressbarView.el.progress.style.display = "block"
      progressbarView.hideFailedMsg()

# these are observed by progressbarModel
progressbarModel.on('run', 'fadeIn', progressbarModel)
progressbarView.on('ratiorendered', 'handleRendered', mediator)
progressbarView.on('fullchange', 'handleFull', mediator)
progressbarView.on('fadeend', 'fadeStop', progressbarModel)
progressbarView.on('hide', 'handleHide', mediator)

# these are observed by progressbarView
progressbarView.changeState(model : progressbarModel._state)
progressbarModel.on('fadingchange', 'fadeInOut', progressbarView)
progressbarModel.on "failedchange", "handleFailedChange", mediator
progressbarView.on('hide', 'initProgressbar', progressbarView)
