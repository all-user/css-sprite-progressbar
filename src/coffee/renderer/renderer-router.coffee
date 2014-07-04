renderer = require './renderer'
progressbarView = require '../progressbar/progressbar-view'

renderer.addUpdater(progressbarView.makeProgressbarUpdate())
