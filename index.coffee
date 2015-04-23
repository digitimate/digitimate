__doc__ = """
An application that provides a service for confirming mobile numbers

"""

koa = require 'koa'
router = require 'koa-router'

formatApiErrors = require './response/formatApiErrors'
secret = require './secret'

# The server is implemented using Koa and generators. See http://koajs.com/.
app = koa()
app.name = 'Digitimate'
app.proxy = true

app.use (next) ->
  @state.config = secret
  yield next

app.use router app
app.get '/', require './routes/home'
app.get '/status', require './routes/status'
app.all '/sendCode', formatApiErrors, require('./routes/codes').sendCodeAsync
app.all '/checkCode', formatApiErrors, require('./routes/codes').checkCodeAsync

if require.main is module
  port = secret?.server?.port ? 3000
  server = app.listen port, ->
    {address: host, port} = server.address()
    console.log "Listening on http://#{ host }:#{ port }"
