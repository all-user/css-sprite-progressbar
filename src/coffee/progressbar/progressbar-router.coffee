progressbarModel = require './progressbar-model'
progressbarView = require './progressbar-view'
renderer = require './../renderer/renderer'

mediator =
  handleRendered : ->
    progressbarModel.stateful.set 'canRenderRatio': no

  handleFull : (statusObj) ->
    progressbarModel.fadeOut() if statusObj.full

  handleHide : ->
    progressbarModel.stateful.set 'hidden': yes
    progressbarModel.resque()
    progressbarModel.stop()

  handleFailedChange: ->
    if progressbarModel.stateful.get 'failed'
      progressbarView.el.arrowBox.style.display =
      progressbarView.el.progress.style.display = 'none'
      progressbarView.showFailedMsg()
    else
      progressbarView.el.arrowBox.style.display =
      progressbarView.el.progress.style.display = 'block'
      progressbarView.hideFailedMsg()

# these are observed by progressbarModel
progressbarModel.on('run', 'fadeIn', progressbarModel)
progressbarView.on('ratiorendered', 'handleRendered', mediator)

progressbarView.stateful.stream
  .distinctUntilChanged (state) -> state.full
  .subscribe(
    mediator.handleFull
    (e) -> console.log 'progressbarView on full changed Error: ', e
    -> console.log 'progressbarView on full changed complete')

progressbarView.on('fadeend', 'fadeStop', progressbarModel)
progressbarView.on('hide', 'handleHide', mediator)

# these are observed by progressbarView
progressbarView.stateful.set 'model': progressbarModel.stateful._state

progressbarModel.stateful.stream
  .distinctUntilChanged (state) -> state.fading
  .subscribe(
    (state) -> progressbarView.fadeInOut state
    (e) -> console.log 'progressbarModel on fading changed Error: ', e
    -> console.log 'progressbarModel on fading changed complete')

progressbarModel.stateful.stream
  .distinctUntilChanged (state) -> state.failed
  .subscribe(
    mediator.handleFailedChange
    (e) -> console.log 'progressbarModel on failed changed Error: ', e
    -> console.log 'progressbarModel on failed changed complete')

progressbarView.on('hide', 'initProgressbar', progressbarView)
