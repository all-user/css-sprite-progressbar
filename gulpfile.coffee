gulp = require 'gulp'
browserify = require 'browserify'
source = require 'vinyl-source-stream'

gulp.task 'script', ->
  browserify
    entries : ['./src/coffee/main/main-router.coffee']
    extensions : ['.coffee']
  .bundle()
  .pipe source 'app.js'
  .pipe gulp.dest './'

gulp.task 'default', ->
  gulp.run 'script'
