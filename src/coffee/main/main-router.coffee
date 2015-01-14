# debug code start ->
window.ltWatch = require '../util/ltWatch'
# <- debug code end

flickrApiManager = require '../flickr/flickr-api-manager'
photosModel = require '../photos/photos-model'

document.addEventListener 'DOMContentLoaded', ->
  inputView = require '../input/input-view'
  require '../photos/photos-router'
  progressbarModel = require '../progressbar/progressbar-model'
  progressbarView = require '../progressbar/progressbar-view'
  require '../progressbar/progressbar-router'
  renderer = require '../renderer/renderer'
  require '../renderer/renderer-router'

  mediator =
    store : {}

    # these methods access to progressbarModel's methods
    setDenomiPhotosLength : (urlArr) ->
      progressbarModel.setDenominator(urlArr.length)

    checkCanQuit : ->
      bool = not flickrApiManager.getState('waiting') and photosModel.getState('completed')
      progressbarModel.changeState(canQuit : bool)

    decideFlowSpeed : ->
      speed =
        if progressbarView.getState('full')
          'fast'
        else if flickrApiManager.getState('waiting')
          'slow'
        else
          'middle'
      progressbarModel.setFlowSpeed(speed)

    # these methods access to renderer's methods
    handleFading : (statusObj) ->
      action = statusObj.fading

      switch action
        when 'stop'
          renderer.deleteUpdater(this.store.fadingUpdater)
        else
          this.store.fadingUpdater = progressbarView.fadingUpdate
          renderer.addUpdater(this.store.fadingUpdater)


  # these are observed by photosModel
  flickrApiManager.on('urlready', 'initPhotos', photosModel)

  # these are observed by progressbarModel
  flickrApiManager.on "apirequestfailed", "failed", progressbarModel
  flickrApiManager.on('urlready', 'setDenomiPhotosLength', mediator)
  photosModel.on('clearunloaded', 'setDenominator', progressbarModel)
  photosModel.on('loadedincreased', 'setNumerator', progressbarModel)

  flickrWaitingChangedStream = flickrApiManager
    .changedStream
    .distinctUntilChanged (state) -> state.waiting

  flickrWaitingChangedStream.subscribe(
    mediator.checkCanQuit,
    (e) -> console.log 'flickrApiManager on waiting changed Error: ', e,
    -> console.log 'flickrApiManager on waiting changed complete')

  flickrWaitingChangedStream.subscribe(
    mediator.decideFlowSpeed,
    (e) -> console.log 'flickrApiManager on waiting changed Error: ', e,
    -> console.log 'flickrApiManager on waiting changed complete')

  photosModel
    .changedStream
    .distinctUntilChanged (state) -> state.completed
    .subscribe(
      mediator.checkCanQuit,
      (e) -> console.log 'flickrApiManager on completed changed Error: ', e,
      -> console.log 'flickrApiManager on completed changed complete')

  photosModel.on('clear', 'clear', progressbarModel)

  progressbarView
    .changedStream
    .distinctUntilChanged (state) -> state.full
    .subscribe(
      mediator.decideFlowSpeed,
      (e) -> console.log 'progressbarView on full changed Error: ', e,
      -> console.log 'progressbarView on full changed complete')

  # these are observed by renderer
  progressbarModel
    .changedStream
    .distinctUntilChanged (state) -> state.fading
    .subscribe(
      (state) ->
        mediator.handleFading state,
      (e) -> console.log 'progressbarModel on fading changed Error: ', e,
      -> console.log 'progressbarModel on fading changed complete')

  progressbarModel.on('run', 'draw', renderer)
  progressbarModel.on('stop', 'pause', renderer)

  # inputView is observed by mediator
  inputView.clickStream
    .filter (e) -> e.target == inputView.elem.canselButton
    .subscribe(
      (e) ->
        photosModel.clearUnloaded()
        if flickrApiManager.getState 'waiting'
          flickrApiManager.changeState 'waiting': no
          progressbarModel.fadeOut()
        if progressbarModel.getState "failed"
          progressbarModel.fadeOut()
      , (e) ->
        console.log 'canselclick subscribe error', e
      , ->
        console.log 'canselclick subscribe on complete')


  inputView.clickStream
    .filter (e) -> e.target == inputView.elem.searchButton
    .subscribe(
      (e) ->
        progressbarModel.run()
        photosModel.clear()
        progressbarModel.resque()
        inputData = inputView.getState()

        flickrApiManager.setAPIOptions
          text: inputView.getState 'searchText'
          per_page: inputView.getState 'perPage'

        photosModel.setProperties
          maxConcurrentRequest: inputView.getState 'maxReq'

        flickrApiManager.sendRequestJSONP()
      , (e) ->
        console.log 'searchclick subscribe error', e
      , ->
        console.log 'searchclick subscribe on complete')
