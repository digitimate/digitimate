__doc__ = """
An application that provides a service for confirming mobile numbers

"""

koa = require 'koa'
gzip = require 'koa-gzip'
router = require 'koa-router'

formatApiErrors = require './response/formatApiErrors'
secret = require './secret'

# The server is implemented using Koa and generators. See http://koajs.com/.
app = koa()
app.name = 'Digitimate'
app.proxy = true

app.use(gzip())

app.use (next) ->
  @state.config = secret
  yield next

siteRouter = router()
siteRouter.get '/', require './routes/home'
siteRouter.get '/status', require './routes/status'
app.use siteRouter.routes()
app.use siteRouter.allowedMethods()

apiRouter = router()
apiRouter.use formatApiErrors
apiRouter.all '/sendCode', require('./routes/codes').sendCodeAsync
apiRouter.all '/checkCode', require('./routes/codes').checkCodeAsync
app.use apiRouter.routes()
app.use apiRouter.allowedMethods()

if require.main is module
  port = secret?.server?.port ? 3000
  server = app.listen port, ->
    {address: host, port} = server.address()
    console.log "Listening on http://#{ host }:#{ port }"
