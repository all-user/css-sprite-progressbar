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
      bool = not flickrApiManager.stateful.get('waiting') and photosModel.stateful.get('completed')
      progressbarModel.stateful.set(canQuit : bool)

    decideFlowSpeed : ->
      speed =
        if progressbarView.stateful.get('full') ## use to switch operator
          'fast'
        else if flickrApiManager.stateful.get('waiting')
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

  flickrWaitingChangedStream = flickrApiManager.stateful.stream
    .distinctUntilChanged (state) -> state.waiting

  flickrWaitingChangedStream.subscribe(
    mediator.checkCanQuit
    (e) -> console.log 'flickrApiManager on waiting changed Error: ', e
    -> console.log 'flickrApiManager on waiting changed complete')

  flickrWaitingChangedStream.subscribe(
    mediator.decideFlowSpeed
    (e) -> console.log 'flickrApiManager on waiting changed Error: ', e
    -> console.log 'flickrApiManager on waiting changed complete')

  photosModel.stateful.stream
    .distinctUntilChanged (state) -> state.completed
    .subscribe(
      mediator.checkCanQuit
      (e) -> console.log 'flickrApiManager on completed changed Error: ', e
      -> console.log 'flickrApiManager on completed changed complete')

  photosModel.on('clear', 'clear', progressbarModel)

  progressbarView.stateful.stream
    .distinctUntilChanged (state) -> state.full
    .subscribe(
      mediator.decideFlowSpeed
      (e) -> console.log 'progressbarView on full changed Error: ', e
      -> console.log 'progressbarView on full changed complete')

  # these are observed by renderer
  progressbarModel.stateful.stream
    .distinctUntilChanged (state) -> state.fading
    .subscribe(
      (state) -> mediator.handleFading state
      (e) -> console.log 'progressbarModel on fading changed Error: ', e
      -> console.log 'progressbarModel on fading changed complete')

  progressbarModel.on('run', 'draw', renderer)
  progressbarModel.on('stop', 'pause', renderer)

  # inputView is observed by mediator
  inputView.clickStream
    .filter (e) -> e.target == inputView.elem.canselButton
    .subscribe(
      (e) ->
        photosModel.clearUnloaded()
        if flickrApiManager.stateful.get 'waiting'
          flickrApiManager.stateful.set 'waiting': no
          progressbarModel.fadeOut()
        if progressbarModel.stateful.get "failed"
          progressbarModel.fadeOut()
      (e) -> console.log 'canselclick subscribe error', e
      -> console.log 'canselclick subscribe on complete')


  inputView.clickStream
    .filter (e) -> e.target == inputView.elem.searchButton
    .subscribe(
      (e) ->
        progressbarModel.run()
        photosModel.clear()
        progressbarModel.resque()
        flickrApiManager.setAPIOptions
          text: inputView.stateful.get 'searchText'
          per_page: inputView.stateful.get 'perPage'
        photosModel.setProperties
          maxConcurrentRequest: inputView.stateful.get 'maxReq'
        flickrApiManager.sendRequestJSONP()
      (e) -> console.log 'searchclick subscribe error', e
      -> console.log 'searchclick subscribe on complete')
