exports = this

exports.photosModel =
  maxConcurrentRequest : 0
  allRequestSize       : 0
  loadedSize           : 0
  photosURLArr         : []
  unloadedURLArr       : []
  photosArr            : []

  _state :
    validated : no
    completed : no

  clear : ->
    this.changeState(
      validated : no
      completed : no
    )
    this.setProperties(
      maxConcurrentRequest : 0
      allRequestSize       : 0
      loadedSize           : 0
      photosURLArr         : []
      unloadedURLArr       : []
      photosArr            : []
    )
    this.fire('clear', null)

  incrementLoadedSize : ->
    this.loadedSize++
    this.fire('loadedincreased', photosModel.loadedSize)
    this.changeState(completed : yes) if this.loadedSize is this.allRequestSize

  initPhotos : (urlArr) ->
    this.setProperties(
      photosURLArr : urlArr
      allRequestSize : urlArr.length
    )
    this.validateProperties()
    this.loadPhotos()

  loadPhotos : ->
    this._load(this.maxConcurrentRequest)

  loadNext : ->
    this._load(1)

  _load : (size) ->
    return if this.unloadedURLArr.length is 0
    this.fire('delegateloading', this.unloadedURLArr.splice(0, size))

  addPhoto : (img) ->
    this.photosArr.push(img)
    this.incrementLoadedSize()

  setProperties : (props) ->
    for own k, v of props
      this[k] = v if this.hasOwnProperty(k)

    this.changeState(validated : no)

  validateProperties : ->
    try
      this.maxConcurrentRequest |= 0
      this.allRequestSize |= 0
      throw new Error('maxConcurrentRequest is Nan') if isNaN(this.maxConcurrentRequest)
      throw new Error('allRequestSize is Nan') if isNaN(this.allRequestSize)

      this.maxConcurrentRequest =
        if this.maxConcurrentRequest > this.allRequestSize
          this.allRequestSize
        else
          if this.maxConcurrentRequest > 0
            this.maxConcurrentRequest
          else
            0

      this.unloadedURLArr = this.photosURLArr.slice()
      this.changeState(validated : yes)
    catch e
      console.log('Error in photosModel.validateProperties')
      console.log("message -> #{ e.message }")
      console.log("stack -> #{ e.stack }")
      console.log("fileName -> #{ e.fileName || e.sourceURL }")
      console.log("line -> #{ e.line || e.lineNumber }")

  getNextPhoto : (received) ->
    return this._getPhotosArr(received, 1)

  _getPhotosArr : (received, length) ->
    sent = []
    res = []

    if received?
      if typeof received is 'number'
        res.push(this.photosArr[received].cloneNode())
        sent = [received]
      else
        j = 0
        for i in [0...length]
          j++ while received[j]
          break unless this.photosArr[j]?
          res[i] = this.photosArr[j].cloneNode()
          sent[i] = j
    else
      res = this.photosArr.slice(0, length)
      for v, i in res
        res[i] = v.cloneNode() # photosArrの中のimgに対しての参照を消す
        sent[i] = i

    res.sent = sent
    res


makePublisher(photosModel)
makeStateful(photosModel)
