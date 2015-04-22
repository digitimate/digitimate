__doc__ = """
An application that provides a service for confirming mobile numbers

"""

assert = require 'assert'
co = require 'co'
express = require 'express'
fs = require 'fs'
instapromise = require 'instapromise'
{
  isBoolean
  isNaN
  isString
} = require 'lodash-node'
timeconstants = require 'timeconstants'
util = require 'util'

r = require './r'
secret = require './secret'
twilio = require './twilio'

DEFAULT_NUMBER_OF_DIGITS = 6
CUSTOM_MESSAGE_CODE_ESCAPE = '{CODE}'
FROM_MOBILE_NUMBER = secret.twilio.fromNumber
PORT = secret?.sever?.port ? 3000

# This doesn't really validate e-mails but is a basic sanity check
EMAIL_REGEX = /.+\@.+\..+/
CUSTOM_MESSAGE_REGEX = new RegExp CUSTOM_MESSAGE_CODE_ESCAPE, 'g'

app = express()

logError = (err) ->
  console.error "Server Error: ", err

_homepageHtml = undefined
app.get '/', (req, res) ->
  co ->
    unless _homepageHtml?
      _homepageHtml = yield fs.promise.readFile './homepage.html', 'utf8'
      if secret?.googleAnalytics?.trackingId?
        googleAnalytics = """
        <script>
          (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
          (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
          m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
          })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

          ga('create', #{ JSON.stringify secret.googleAnalytics.trackingId }, 'auto');
          ga('send', 'pageview');
        </script>
        """
        _homepageHtml = _homepageHtml.replace '<!-- Google Analytics -->', googleAnalytics
    res.type 'text/html'
    res.send _homepageHtml
    _homepageHtml = null # No caching while we're developing
  .catch (err) ->
    logError err
    res.status 500
    res.send "Server Error: ", err

app.all '/sendCode', (req, res) ->
  co ->
    res.type 'application/json'

    {
      userMobileNumber
      numberOfDigits
      message
      developerEmail
    } = req.query

    console.log "Request to sendCode for '#{ developerEmail }' for #{ userMobileNumber }"

    badRequest = _badRequestFactory res

    if _basicValidateRequest badRequest, req
      return

    if numberOfDigits?
      numberOfDigits = parseInt numberOfDigits
      if isNaN numberOfDigits
        return badRequest "`numberOfDigits` must be a number"
      else
        if numberOfDigits < 3
          return badRequest "`numberOfDigits` must be at least 3"
        else if numberOfDigits > 24
          return badRequest "`numberOfDigits` must be 24 or less"
    else
      numberOfDigits = DEFAULT_NUMBER_OF_DIGITS

    try
      yield sendCodeAsync {
        developerEmail
        message
        userMobileNumber
        numberOfDigits
      }
      res.send {
        success: true
        userMobileNumber
      }
    catch err
      logError err
      res.status 500
      res.send {
        success: false
        err: "Server Error: #{ util.format err }"
        userMobileNumber
      }
  .catch (err) ->
    logError err
    res.status 500
    res.send {
      success: false
      err: "Server Error: #{ util.format err }"
    }

app.get '/status', (req, res) ->
  res.type 'application/json'
  res.send status: 'ok'

app.all '/checkCode', (req, res) ->
  co ->
    res.type 'application/json'

    {
      userMobileNumber
      developerEmail
      code
    } = req.query

    ip = req.headers['x-forwarded-for'] || req.connection.remoteAddress

    badRequest = _badRequestFactory res

    if _basicValidateRequest badRequest, req
      return

    unless code?
      return badRequest "`code` must be provided"

    try
      validCode = yield checkCodeAsync {
        developerEmail
        code
        userMobileNumber
      }
      validCode = !!validCode
      res.send {
        success: true
        validCode
        userMobileNumber
      }
    catch err
      logError err
      res.status 500
      res.send {
        success: false
        err: "Server Error: #{ util.format err }"
        userMobileNumber
      }
  .catch (err) ->
    logError err
    res.status 500
    res.send {
      success: false
      err: "Server Error: #{ util.format err }"
    }


_badRequestFactory = (res) ->
  """Returns a function that sends bad request responses"""

  badRequest = (message) ->
    console.log "Bad Request: #{ message }"
    res.status 400
    res.send {
      success: false
      err: "Bad Request: #{ message }"
    }
    true


_basicValidateRequest = (badRequest, req) ->
  """Validates `developerEmail` and `userMobileNumber`"""

  {
    developerEmail
    userMobileNumber
  } = req.query

  unless isString developerEmail
    return badRequest "`developerEmail` query parameter must be provided and be a string"

  unless developerEmail.match EMAIL_REGEX
    return badRequest "`developerEmail` doesn't look like an e-mail address!"

  unless developerEmail.length >= 3
    return badRequest "`developerEmail` must be at least 3 characters long"

  unless developerEmail.length < 256
    return badRequest "`developerEmail` must be less than 256 characters long"

  unless isString userMobileNumber
    return badRequest "`userMobileNumber` must be provided and be a string"

  unless userMobileNumber.length > 5
    return badRequest "`userMobileNumber` must be at least 5 digits long"

  unless userMobileNumber.length < 100
    return badRequest "`userMobileNumber` must be less than 100 characters long"

  false


sendSmsAsync = co.wrap (userMobileNumber, message) ->
  """Sends an SMS to a given number"""

  yield return twilio.promise.sendMessage {
    to: userMobileNumber
    from: FROM_MOBILE_NUMBER
    body: message
  }

sendCodeAsync = co.wrap (opts) ->
  """Makes a code and sends it to a given number"""

  {
    developerEmail
    numberOfDigits
    userMobileNumber
    message
  } = opts

  numberOfDigits ?= DEFAULT_NUMBER_OF_DIGITS
  code = makeCode numberOfDigits
  sentTime = Date.now()

  yield r.table('codes').insert({
    developerEmail
    userMobileNumber
    message
    code
    sentTime
  })

  message ?= "Code:"

  if contains message, CUSTOM_MESSAGE_CODE_ESCAPE
    messageToSend = message.replace CUSTOM_MESSAGE_REGEX, code
  else
    messageToSend = "#{ message } #{ code }"


  yield return sendSmsAsync userMobileNumber, messageToSend

checkCodeAsync = co.wrap (opts) ->
  """Checks a code"""

  {
    developerEmail
    userMobileNumber
    code
    ip
  } = opts

  now = Date.now()
  anHourAgo = now - timeconstants.hour

  results = yield r.table('codes').filter({
    developerEmail
    code
    userMobileNumber
  })

  if (row = results[0])?
    if row.sentTime > anHourAgo and not row.used
      validCode = true
      try
        yield r.table('codes').filter({
          developerEmail
          code
          userMobileNumber
        }).update({used: true})
      catch
        # Just log this; we still want to say the code is valid
        console.error "Failed to mark code '#{ code }' for mobile number #{ userMobileNumber } for developer '#{ developerEmail }' as used"
    else
      validCode = false

  else
    console.log "Failed attempt from #{ ip } for '#{ developerEmail }' for number #{ userMobileNumber } with code #{ code }"
    yield r.table('failedAttempts').insert({
      developerEmail
      code
      userMobileNumber
      attemptTime: now
      ip
    })
    validCode

  validCode

contains = (haystack, needle) ->
  haystack.indexOf(needle) > -1


makeCode = (numberOfDigits=DEFAULT_NUMBER_OF_DIGITS) ->
  """Generates a new code `numberOfDigits` digits long"""

  digit = -> Math.floor(Math.random() * 10)
  code = (digit() for _ in [0...numberOfDigits]).join ''


if require.main is module
  server = app.listen PORT, ->
    host = server.address().address
    port = server.address().port
    console.log "Listening on http://%s:%s", host, port


module.exports = {
  __doc__
  app
  checkCodeAsync
  makeCode
  r
  twilio
  sendCodeAsync
  sendSmsAsync
  DEFAULT_NUMBER_OF_DIGITS
  EMAIL_REGEX
  FROM_MOBILE_NUMBER
}
