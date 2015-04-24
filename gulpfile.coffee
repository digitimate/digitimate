child_process = require 'child_process'
coffeeScript = require 'coffee-script'
path = require 'path'

gulp = require 'gulp'
gutil = require 'gulp-util'

serverProcess = null

startServer = ->
  coffeeScript.register()
  serverScriptPath = path.join __dirname, '/server/index.coffee'
  serverOptions = execArgv: []
  serverProcess = child_process.fork serverScriptPath, serverOptions
  serverProcess.on 'error', (error) ->
    restartServer()
  gutil.log "Started a new server process (#{ serverProcess.pid })"

stopServer = ->
  if not serverProcess?
    gutil.log "The server is not already running"
  else
    gutil.log "Shutting down server process... (#{ serverProcess.pid })"
    killed = serverProcess.kill 'SIGKILL'
    if not killed
      gutil.log "Failed to kill server process (#{ serverProcess.pid })"
    if not serverChildProcess.killed
      gutil.log "Server process not in killed state (#{ serverProcess.pid })"
    serverProcess = null

restartServer = ->
  gutil.log "Restarting server..."
  stopServer()
  startServer()

gulp.task 'run', ->
  startServer()

gulp.task 'default', ['run']
