progressbarModel = require './progressbar-model'
progressbarView = require './progressbar-view'

mediator =
  handleRendered : ->
    progressbarModel.stateful.set 'canRenderRatio': no

  handleFull : (statusObj) ->
    progressbarModel.fadeOut() if statusObj.full

  handleHide : ->
    progressbarModel.stateful.set 'hidden': yes
    progressbarModel.resque()
    progressbarModel.stop()

  handleFailedChange: (failed) ->
    if failed
      progressbarView.el.arrowBox.style.display =
      progressbarView.el.progress.style.display = 'none'
      progressbarView.showFailedMsg()
    else
      progressbarView.el.arrowBox.style.display =
      progressbarView.el.progress.style.display = 'block'
      progressbarView.hideFailedMsg()

# these are observed by progressbarModel
progressbarModel.eventStream
  .filter (e) -> e.type is 'run'
  .subscribe(
    (e) -> progressbarModel.fadeIn e.data
    (e) -> console.log 'progressbarModel on run Error: ', e
    -> console.log 'progressbarModel on run complete')

progressbarView.eventStream
  .filter (e) -> e.type is 'ratiorendered'
  .subscribe(
    (e) -> mediator.handleRendered e.data
    (e) -> console.log 'progressbarView on ratiorendered Error: ', e
    -> console.log 'progressbarView on ratiorendered complete')

progressbarView.stateful.stream
  .distinctUntilChanged (state) -> state.full
  .subscribe(
    mediator.handleFull
    (e) -> console.log 'progressbarView on full changed Error: ', e
    -> console.log 'progressbarView on full changed complete')

progressbarView.eventStream
  .filter (e) -> e.type is 'fadeend'
  .subscribe(
    (e) -> progressbarModel.fadeStop e.data
    (e) -> console.log 'progressbarView on fadeend Error: ', e
    -> console.log 'progressbarView on fadeend complete')

progressbarView.eventStream
  .filter (e) -> e.type is 'hide'
  .subscribe(
    (e) -> mediator.handleHide e.data
    (e) -> console.log 'progressbarView on hide Error: ', e
    -> console.log 'progressbarView on hide complete')

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
    (state) -> mediator.handleFailedChange state.failed
    (e) -> console.log 'progressbarModel on failed changed Error: ', e
    -> console.log 'progressbarModel on failed changed complete')

progressbarView.eventStream
  .filter (e) -> e.type is 'hide'
  .subscribe(
    (e) -> progressbarView.initProgressbar e.data
    (e) -> console.log 'progressbarView on hide Error: ', e
    -> console.log 'progressbarView on hide complete')
