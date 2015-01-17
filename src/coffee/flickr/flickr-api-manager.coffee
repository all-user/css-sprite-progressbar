Rx = require 'rx'
makeStateful = require '../util/stateful'

window.jsonFlickrApi = (json) ->
  jsonFlickrApi.eventStream.onNext
    'type': 'apiresponse'
    'data': json
jsonFlickrApi.eventStream = new Rx.Subject()

initialState = 'waiting': no


flickrApiManager =
  eventStream: new Rx.Subject()

  apiOptions :
    apiKey : 'a3d606b00e317c733132293e31e95b2e'
    format : 'json'
    noJsonCallback : false
    others :
      text : ''
      sort : 'date-posted-desc'
      per_page : 0

  setAPIOptions : (options) ->
    for own k, v of options
      if this.apiOptions.hasOwnProperty(k)
        this.apiOptions[k] = v
      else
        this.apiOptions.others[k] = v

  validateOptions : ->
    try
      perPage = +this.apiOptions.others.per_page
      throw new Error("per_page is NaN") if isNaN(perPage)
      negative = perPage < 0
      this.apiOptions.others.per_page = 0 if negative
    catch e
      console.log('Error in flickrApiManager.validateOptions')
      console.log("message -> #{ e.message }")
      console.log("stack -> #{ e.stack }")
      console.log("fileName -> #{ e.fileName || e.sourceURL }")
      console.log("line -> #{ e.line || e.lineNumber }")

  sendRequestJSONP : (options) ->
    return false if this.stateful.get 'waiting'
    this.stateful.set 'waiting', yes
    newScript = document.createElement('script')
    oldScript = document.getElementById('kick-api')
    this.setAPIOptions(options) if options?
    this.validateOptions()
    newScript.id = 'kick-api'
    newScript.src = this.genURI(this.apiOptions)
    newScript.onerror = (e) =>
      this.stateful.set 'waiting', no
      this.eventStream.onNext
        'type': 'apirequestfailed'
        'data': e
    if oldScript?
      document.body.replaceChild(newScript, oldScript)
    else
      document.body.appendChild(newScript)
    this.eventStream.onNext
      'type': 'sendrequest'
      'data': null

  genURI : (options) ->
    uri = "api_key=#{options.apiKey}"
    for own k, v of options.others
      uri += "&#{k}=#{v}"
    uri += "&format=#{options.format}"
    noJsonp = options.format is 'json' and options.noJsonCallback
    uri += 'noJsonCallback' if noJsonp
    return "https://api.flickr.com/services/rest/?method=flickr.photos.search&#{uri}"

  genPhotosURLArr : (json) ->
    for v, i in json.photos.photo
      "http://farm#{v.farm}.staticflickr.com/#{v.server}/#{v.id}_#{v.secret}.jpg"

  handleAPIResponse : (json) ->
    if this.stateful.get 'waiting'
      this.stateful.set 'waiting', no
      this.eventStream.onNext
        'type': 'apiresponse'
        'data': json
      this.eventStream.onNext
        'type': 'urlready'
        'data': this.genPhotosURLArr json


makeStateful flickrApiManager, initialState
jsonFlickrApi.eventStream
  .filter (e) -> e.type is 'apiresponse'
  .subscribe(
    (e) -> flickrApiManager.handleAPIResponse e.data
    (e) -> console.log 'jsonFlickrApi on apiresponse Error: ', e
    -> console.log 'jsonFlickrApi on apiresponse complete')

module.exports = flickrApiManager
