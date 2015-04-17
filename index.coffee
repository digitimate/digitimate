__doc__ = """
An application that provides a service for confirming mobile numbers

"""

co = require 'co'
express = require 'express'
fs = require 'fs'
instapromise = require 'instapromise'
{
  isNaN
  isString
} = require 'lodash-node'
timeconstants = require 'timeconstants'

r = require './r'
twilio = require './twilio'

DEFAULT_NUMBER_OF_DIGITS = 6
FROM_MOBILE_NUMBER = '+1 650-479-1412'
CUSTOM_MESSAGE_CODE_ESCAPE = '{CODE}'

app = express()

_homepageHtml = undefined
app.get '/', (req, res) ->
  co ->
    unless _homepageHtml?
      _homepageHtml = yield fs.promise.readFile './homepage.html', 'utf8'
    res.type 'text/html'
    res.send _homepageHtml
  res.send

_bootstrapCss = undefined
app.get '/bootstrap.min.css', (req, res) ->
  co ->
    unless _bootstrapCss?
      _bootstrapCss = yield fs.promise.readFile './bootstrap.min.css', 'utf8'
    res.type 'text/css'
    res.send _bootstrapCss

app.all '/sendCode', (req, res) ->
  co ->
    res.type 'application/json'

    {
      mobileNumber
      numberOfDigits
      message
      appName
    } = req.query

    console.log "Request to sendCode for app #{ appName } for #{ mobileNumber }"

    badRequest = _badRequestFactory res

    if _basicValidateRequest badRequest, req
      return

    if numberOfDigits?
      numberOfDigits = parseInt numberOfDigits
      if isNaN numberOfDigits
        return badRequest "`numberOfDigits` must be a number"
      else
        if numberOfDigits < 1
          return badRequest "`numberOfDigits` must be at least 1"
        else if numberOfDigits > 24
          return badRequest "`numberOfDigits` must be 24 or less"
    else
      numberOfDigits = DEFAULT_NUMBER_OF_DIGITS

    try
      yield sendCodeAsync {
        appName
        message
        mobileNumber
        numberOfDigits
      }
      res.send JSON.stringify {
        ok: true
        mobileNumber
      }
    catch err
      res.status 500
      res.send JSON.stringify {
        success: false
        err: "Server Error: #{ err }"
        mobileNumber
      }

app.all '/checkCode', (req, res) ->
  co ->
    res.type 'application/json'

    {
      mobileNumber
      appName
      code
    } = req.query

    ip = req.headers['x-forwarded-for'] || req.connection.remoteAddress

    badRequest = _badRequestFactory res

    if _basicValidateRequest badRequest, req
      return

    unless code?
      return badRequest "`code` must be provided"

    try
      validCode = checkCodeAsync {
        appName
        code
        mobileNumber
      }
      res.send JSON.stringify {
        success: true
        validCode
        mobileNumber
      }
    catch err
      res.status 500
      res.send {
        success: false
        err: "Server Error: #{ err }"
        mobileNumber
      }

_badRequestFactory = (res) ->
  """Returns a function that sends bad request responses"""

  badRequest = (message) ->
    console.log "Bad Request: #{ message }"
    res.status 400
    res.send JSON.stringify {
      success: false
      err: "Bad Request: #{ message }"
    }
    true


_basicValidateRequest = (badRequest, req) ->
  """Validates `appName` and `mobileNumber`"""

  {
    appName
    mobileNumber
  } = req.query

  unless isString appName
    return badRequest "`appName` query paramter must be provided and be a string"

  unless appName.length >= 3
    return badRequest "`appName` must be at least 3 characters long"

  unless appName.length < 256
    return badRequest "`appName` must be less than 256 characters long"

  unless isString mobileNumber
    return badRequest "`mobileNumber` must be provided and be a string"

  unless mobileNumber.length > 5
    return badRequest "`mobileNumber` must be at least 5 digits long"

  unless mobileNumber.length < 100
    return badRequest "`mobileNumber` must be less than 100 characters long"

  false


sendSmsAsync = co.wrap (mobileNumber, message) ->
  """Sends an SMS to a given number"""

  yield twilio.promise.sendMessage {
    to: mobileNumber
    from: FROM_MOBILE_NUMBER
    body: message
  }

sendCodeAsync = co.wrap (opts) ->
  """Makes a code and sends it to a given number"""

  {
    appName
    numberOfDigits
    mobileNumber
    message
  } = opts

  numberOfDigits ?= DEFAULT_NUMBER_OF_DIGITS
  code = makeCode numberOfDigits
  sentTime = Date.now()

  yield r.table('codes').insert({
    appName
    mobileNumber
    message
    code
    sentTime
  })

  message ?= "Code:"

  if contains message, CUSTOM_MESSAGE_CODE_ESCAPE
    messageToSend = message.replace CUSTOM_MESSAGE_CODE_ESCAPE, code
  else
    messageToSend = "#{ message } #{ code }"


  yield sendSmsAsync mobileNumber, messageToSend

checkCodeAsync = co.wrap (opts) ->
  """Checks a code"""

  {
    appName
    mobileNumber
    code
    ip
  } = opts

  now = Date.now()
  anHourAgo = now - timeconstants.hour

  results = yield r.table('codes').filter({
    appName
    code
    mobileNumber
  })

  if (row = results[0])?
    if row.sentTime > anHourAgo and not row.used
      validCode = true
      try
        yield r.table('codes').filter({
          appName
          code
          mobileNumber
        }).update({used: true})
      catch
        # Just log this; we still want to say the code is valid
        console.error "Failed to mark code '#{ code }' for mobile number #{ mobileNumber } on app '#{ appName }' as used"
    else
      validCode = false

  else
    console.log "Failed attempt from #{ ip } for app '#{ appName }' for number #{ mobileNumber } with code #{ code }"
    yield r.table('failedAttempts').insert({
      appName
      code
      mobileNumber
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
  server = app.listen 3000, ->
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
  FROM_MOBILE_NUMBER
}
