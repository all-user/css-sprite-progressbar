document.addEventListener('DOMContentLoaded', ->
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

    # these methods access to renerer's methods
    handleFading : (statusObj) ->
      action = statusObj.fading

      switch action
        when 'stop'
          renderer.deleteUpdater(this.store.fadingUpdater)
        else
          this.store.fadingUpdater = progressbarView.fadingUpdate
          renderer.addUpdater(this.store.fadingUpdater)

    # inputView is observed by these methods
    handleButtonClick : ->
      progressbarModel.run()
      photosModel.clear()
      flickrApiManager.setAPIOptions(inputView.getOptions())
      photosModel.setProperties(maxConcurrentRequest : inputView.getMaxConcurrentRequest())
      flickrApiManager.sendRequestJSONP()

  # these are observed by photosModel
  flickrApiManager.on('urlready', 'initPhotos', photosModel)

  # these are observed by progressbarModel
  flickrApiManager.on('urlready', 'setDenomiPhotosLength', mediator)
  photosModel.on('loadedincreased', 'setNumerator', progressbarModel)
  flickrApiManager.on('waitingchange', 'checkCanQuit', mediator)
  photosModel.on('completedchange', 'checkCanQuit', mediator)
  flickrApiManager.on('waitingchange', 'decideFlowSpeed', mediator)
  photosModel.on('clear', 'clear', progressbarModel)
  progressbarView.on('fullchange', 'decideFlowSpeed', mediator)

  # these are observed by renderer
  progressbarModel.on('fadingchange', 'handleFading', mediator)
  progressbarModel.on('run', 'draw', renderer)
  progressbarModel.on('stop', 'pause', renderer)

  # inputView is observed by mediator
  inputView.on('searchclick', 'handleButtonClick', mediator)
)
