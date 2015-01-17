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
        if progressbarView.stateful.get('full')
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
        when 'in', 'out'
          this.store.fadingUpdater = progressbarView.fadingUpdate
          renderer.addUpdater(this.store.fadingUpdater)
        else
          console.error 'switch value exception error', action


  # these are observed by photosModel
  flickrUrlReady = flickrApiManager.eventStream
    .filter (e) -> e.type is 'urlready'

  flickrUrlReady.subscribe(
    (e) -> photosModel.initPhotos e.data
    (e) -> console.log 'flickrApiManager on urlready Error: ', e
    -> console.log 'flickrApiManager on urlready complete')

  # these are observed by progressbarModel
  flickrUrlReady.subscribe(
    (e) -> mediator.setDenomiPhotosLength e.data
    (e) -> console.log 'flickrApiManager on urlready Error: ', e
    -> console.log 'flickrApiManager on urlready complete')

  flickrApiManager.eventStream
    .filter (e) -> e.type is 'apirequestfailed'
    .subscribe(
      (e) -> progressbarModel.failed e.data
      (e) -> console.log 'flickrApiManager on apirequestfailed Error: ', e
      -> console.log 'flickrApiManager on apirequestfailed complete')

  photosModel.eventStream
    .filter (e) -> e.type is 'clearunloaded'
    .subscribe(
      (e) -> progressbarModel.setDenominator e.data
      (e) -> console.log 'photosModel on clearunloaded Error: ', e
      -> console.log 'photosModel on clearunloaded complete')

  photosModel.eventStream
    .filter (e) -> e.type is 'loadedincreased'
    .subscribe(
      (e) -> progressbarModel.setNumerator e.data
      (e) -> console.log 'photosModel on loadedincreased Error: ', e
      -> console.log 'photosModel on loadedincreased complete')

  flickrWaiting = flickrApiManager.stateful.stream
    .distinctUntilChanged (state) -> state.waiting

  photosModelCompleted = photosModel.stateful.stream
    .distinctUntilChanged (state) -> state.completed

  progressbarViewFull = progressbarView.stateful.stream
    .distinctUntilChanged (state) -> state.full

  flickrWaiting
    .merge progressbarViewFull
    .subscribe(
      mediator.decideFlowSpeed
      (e) -> console.log 'flickrApiManager on waiting changed Error: ', e
      -> console.log 'flickrApiManager on waiting changed complete')

  flickrWaiting
    .merge photosModelCompleted
    .subscribe(
      mediator.checkCanQuit
      (e) -> console.log 'flickrWaiting and photosModelCompleted changed Error: ', e
      -> console.log 'flickrWaiting and photosModelCompleted changed complete')

  photosModel.eventStream
    .filter (e) -> e.type is 'clear'
    .subscribe(
      (e) -> progressbarModel.clear e.data
      (e) -> console.log 'photosModel on clear changed Error: ', e
      -> console.log 'photosModel on clear changed complete')


  # these are observed by renderer
  progressbarModel.stateful.stream
    .distinctUntilChanged (state) -> state.fading
    .subscribe(
      (state) -> mediator.handleFading state
      (e) -> console.log 'progressbarModel on fading changed Error: ', e
      -> console.log 'progressbarModel on fading changed complete')

  progressbarModel.eventStream
    .filter (e) -> e.type is 'run'
    .subscribe(
      (e) -> renderer.draw e.data
      (e) -> console.log 'progressbarModel on run Error: ', e
      -> console.log 'progressbarModel on run complete')

  progressbarModel.eventStream
    .filter (e) -> e.type is 'stop'
    .subscribe(
      (e) -> renderer.pause e.data
      (e) -> console.log 'progressbarModel on stop Error: ', e
      -> console.log 'progressbarModel on stop complete')

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
