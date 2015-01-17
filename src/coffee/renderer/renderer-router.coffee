renderer = require './renderer'
progressbarView = require '../progressbar/progressbar-view'

progressbarView.setGlobalFPS renderer.targetFPS

renderer.addUpdater progressbarView.makeProgressbarUpdate()
