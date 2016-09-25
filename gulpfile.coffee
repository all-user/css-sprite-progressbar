gulp = require 'gulp'
gutil = require 'gulp-util'
browserify = require 'browserify'
source = require 'vinyl-source-stream'
coffeelint = require 'gulp-coffeelint'
coffee = require 'gulp-coffee'
watchify = require 'watchify'
merge = (require 'event-stream').merge
shell = require 'gulp-shell'

gulp.task 'browserify', ->
  browserify
    entries : ['./src/coffee/main/main-subscription.coffee']
    extensions : ['.coffee']
  .bundle()
  .pipe source 'app.js'
  .pipe gulp.dest './'

gulp.task 'watch', ->
  bundler =
    watchify
      entries : ['./src/coffee/main/main-subscription.coffee']
      extensions : ['.coffee']
      verbose : on
  rebundle = ->
    bundler.bundle()
    .on 'error', (e) ->
      gutil.log 'Browserify Error', e
    .pipe source 'app.js'
    .pipe gulp.dest './'
  bundler.on 'update', rebundle
  rebundle()

gulp.task 'lint', ->
  gulp.src ['./src/coffee/**/*.coffee', './src/coffee/*.coffee']
    .pipe coffeelint()
    .pipe coffeelint.reporter()


gulp.task 'paraout', ->
  dir = [
    'flickr'
    'input'
    'photos'
    'progressbar'
    'renderer'
    'util'
    'main'
    'test'
  ]

  tasks = []
  for d in dir
    tasks.push(gulp.src "./src/coffee/#{ d }/*.coffee"
      .pipe coffee()
      .pipe gulp.dest "./src/js/#{ d }/"
    )

  merge tasks...


gulp.task 'build_test_case', ->
  tests = [
    'DHTMLSpriteTest'
  ]

  tasks = tests.map (testName) ->
    browserify
      entries : ["./src/coffee/test/#{ testName }.coffee"]
      extensions : ['.coffee']
    .bundle()
    .pipe source 'test.js'
    .pipe gulp.dest "./test/#{ testName }/"

  merge tasks...


gulp.task 'jsduck', ['paraout'], shell.task ['jsduck -o ./docs --config=jsduck.json']


gulp.task 'default', ['lint', 'browserify', 'jsduck']
