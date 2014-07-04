gulp = require 'gulp'
browserify = require 'browserify'
source = require 'vinyl-source-stream'
coffeelint = require 'gulp-coffeelint'

gulp.task 'browserify', ->
  browserify
    entries : ['./src/coffee/main/main-router.coffee']
    extensions : ['.coffee']
  .bundle()
  .pipe source 'app.js'
  .pipe gulp.dest './'

gulp.task 'lint', ->
  gulp.src './src/coffee/**/*.coffee', './src/coffee/*.coffee'
  .pipe coffeelint()
  .pipe coffeelint.reporter()

gulp.task 'default', ->
  gulp.run 'lint'
  gulp.run 'browserify'
