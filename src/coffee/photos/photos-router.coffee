photosModel = require './photos-model'
photosView = require './photos-view'
preloader = require './preloader'

mediator =
  appendNextPhoto : ->
    photos =
      photosModel.getNextPhoto photosView.getAppended()
    photos[0].className = 'flickr-img'
    photosView.appendPhotos photos


# preloader
photosModel.eventStream
  .filter (e) -> e.type is 'delegateloading'
  .subscribe(
    (e) -> preloader.preload e.data
    (e) -> console.log 'photosModel on delegateloading Error: ', e
    -> console.log 'photosModel on delegateloading complete')

# photosModel

photosModelLoadedIncreased = photosModel.eventStream
  .filter (e) -> e.type is 'loadedincreased'

photosModelLoadedIncreased.subscribe(
  (e) -> photosModel.loadNext e.data
  (e) -> console.log 'photosModel on loadedincreased Error: ', e
  -> console.log 'photosModel on loadedincreased complete')

preloader.eventStream
  .filter (e) -> e.type is 'loaded'
  .subscribe(
    (e) -> photosModel.addPhoto e.data
    (e) -> console.log 'preloader on loaded Error: ', e
    -> console.log 'preloader on loaded complete')

# photosView
photosModelLoadedIncreased.subscribe(
  (e) -> mediator.appendNextPhoto e.data
  (e) -> console.log 'photosModel on loadedincreased Error: ', e
  -> console.log 'photosModel on loadedincreased complete')

photosModel.eventStream
  .filter (e) -> e.type is 'clear'
  .subscribe(
    (e) -> photosView.clear e.data
    (e) -> console.log 'photosModel on clear Error: ', e
    -> console.log 'photosModel on clear complete')
