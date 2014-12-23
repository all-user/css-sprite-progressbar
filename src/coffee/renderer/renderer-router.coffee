renderer = require './renderer'
progressbarView = require '../progressbar/progressbar-view'

progressbarView.setGlobalFPS renderer.targetFPS
progressbarView.setFramerate renderer.framerate

renderer.addUpdater(progressbarView.makeProgressbarUpdate())
