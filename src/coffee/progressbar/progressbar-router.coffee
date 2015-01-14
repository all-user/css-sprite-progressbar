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
      progressbarView.showFailedMsg()
    else
      progressbarView.el.arrowBox.style.display =
      progressbarView.el.progress.style.display = "block"
      progressbarView.hideFailedMsg()

# these are observed by progressbarModel
progressbarModel.on('run', 'fadeIn', progressbarModel)
progressbarView.on('ratiorendered', 'handleRendered', mediator)

progressbarView
  .changedStream
  .distinctUntilChanged (state) -> state.full
  .subscribe(
    mediator.handleFull,
    (e) -> console.log 'progressbarView on full changed Error: ', e,
    -> console.log 'progressbarView on full changed complete')

progressbarView.on('fadeend', 'fadeStop', progressbarModel)
progressbarView.on('hide', 'handleHide', mediator)

# these are observed by progressbarView
progressbarView.changeState(model : progressbarModel._state)

progressbarModel
  .changedStream
  .distinctUntilChanged (state) -> state.fading
  .subscribe(
    (state) -> progressbarView.fadeInOut state,
    (e) -> console.log 'progressbarModel on fading changed Error: ', e,
    -> console.log 'progressbarModel on fading changed complete')

progressbarModel
  .changedStream
  .distinctUntilChanged (state) -> state.failed
  .subscribe(
    mediator.handleFailedChange,
    (e) -> console.log 'progressbarModel on failed changed Error: ', e,
    -> console.log 'progressbarModel on failed changed complete')

progressbarView.on('hide', 'initProgressbar', progressbarView)
