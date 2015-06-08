# debug code start ->
window.ltWatch = require '../util/ltWatch'
# <- debug code end

flickrAPIManager = require '../flickr/flickr-api-manager'
photosModel = require '../photos/photos-model'

document.addEventListener 'DOMContentLoaded', ->
  inputView = require '../input/input-view'
  require '../photos/photos-operation'
  renderer = require '../renderer/renderer'
  { progressbarModel, progressbarView } =
    require '../progressbar/progressbar-operation'

  renderer.addUpdater progressbarView.makeProgressbarUpdate()

  mediator =
    store : {}

    # these methods access to progressbarModel's methods
    setDenomiPhotosLength : (urlArr) ->
      progressbarModel.setDenominator(urlArr.length)

    checkCanQuit : ->
      bool =
        not flickrAPIManager.stateful.get('waiting') and
        photosModel.stateful.get('completed')
      progressbarModel.stateful.set canQuit: bool

    decideFlowSpeed : ->
      speed =
        if progressbarView.stateful.get('full')
          'fast'
        else if flickrAPIManager.stateful.get('waiting')
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
  flickrUrlReady =
    flickrAPIManager.eventStream
    .filter (e) -> e.type is 'urlready'

  flickrUrlReady.subscribe(
    (e) -> photosModel.initPhotos e.data
    (e) -> console.log 'flickrAPIManager on urlready Error: ', e
    -> console.log 'flickrAPIManager on urlready complete')

  # these are observed by progressbarModel
  flickrUrlReady.subscribe(
    (e) -> mediator.setDenomiPhotosLength e.data
    (e) -> console.log 'flickrAPIManager on urlready Error: ', e
    -> console.log 'flickrAPIManager on urlready complete')

  flickrAPIManager.eventStream
  .filter (e) -> e.type is 'apirequestfailed'
  .subscribe(
    (e) -> console.log e.data; progressbarModel.failed e.data
    (e) -> console.log 'flickrAPIManager on apirequestfailed Error: ', e
    -> console.log 'flickrAPIManager on apirequestfailed complete')

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

  flickrWaiting =
    flickrAPIManager.stateful.stream
    .distinctUntilChanged (state) -> state.waiting

  photosModelCompleted =
    photosModel.stateful.stream
    .distinctUntilChanged (state) -> state.completed

  progressbarViewFull =
    progressbarView.stateful.stream
    .distinctUntilChanged (state) -> state.full

  flickrWaiting
  .merge progressbarViewFull
  .subscribe(
    mediator.decideFlowSpeed
    (e) -> console.log 'flickrAPIManager on waiting changed Error: ', e
    -> console.log 'flickrAPIManager on waiting changed complete')

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
      if flickrAPIManager.stateful.get 'waiting'
        flickrAPIManager.stateful.set 'waiting': no
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
      photosModel.setProperties
        maxConcurrentRequest: inputView.stateful.get 'maxReq'
      flickrAPIManager.sendRequestJSONP
        text    : inputView.stateful.get 'searchText'
        per_page: inputView.stateful.get 'perPage'
    (e) -> console.log 'searchclick subscribe error', e
    -> console.log 'searchclick subscribe on complete')
