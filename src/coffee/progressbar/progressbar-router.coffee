progressbarModel = require './progressbar-model'
progressbarView = require './progressbar-view'

mediator =
  handleRendered : ->
    progressbarModel.changeState(canRenderRatio : no)

  handleFull : (statusObj) ->
    progressbarModel.fadeOut() if statusObj.full

  handleHide : ->
    progressbarModel.changeState(hidden : yes)
    progressbarModel.stop()

# these are observed by progressbarModel
progressbarModel.on('run', 'fadeIn', progressbarModel)
progressbarView.on('ratiorendered', 'handleRendered', mediator)
progressbarView.on('fullchange', 'handleFull', mediator)
progressbarView.on('fadeend', 'fadeStop', progressbarModel)
progressbarView.on('hide', 'handleHide', mediator)

# these are observed by progressbarView
progressbarView.changeState(model : progressbarModel._state)
progressbarModel.on('fadingchange', 'fadeInOut', progressbarView)
progressbarView.on('hide', 'initProgressbar', progressbarView)
