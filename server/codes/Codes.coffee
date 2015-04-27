co = require 'co'

Twilio = require './Twilio'

r = require '../database/rethinkdb'
secret = require '../secret'

DEFAULT_NUMBER_OF_DIGITS = 6
CUSTOM_MESSAGE_CODE_PLACEHOLDER = '{CODE}'
# TODO: Escape the placeholder if we support arbitrary ones
CUSTOM_MESSAGE_CODE_REGEX = new RegExp CUSTOM_MESSAGE_CODE_PLACEHOLDER, 'g'
CODE_LIFETIME_SECONDS = 3600

sendCodeAsync = co.wrap (ctx, options) ->
  """Makes a code and sends it to a given number"""
  {
    developerEmail
    numberOfDigits
    userMobileNumber
    message
    ip
    test
  } = options

  numberOfDigits ?= DEFAULT_NUMBER_OF_DIGITS
  code = makeCode numberOfDigits

  yield r.table('codes').insert {
    developerEmail
    userMobileNumber
    message
    code
    sentTime: r.now()
    ip
    test
  }

  message ?= 'Code:'
  if message.indexOf(CUSTOM_MESSAGE_CODE_PLACEHOLDER) isnt -1
    messageToSend = message.replace CUSTOM_MESSAGE_CODE_REGEX, code
  else
    messageToSend = "#{ message } #{ code }"

  if not test
    yield sendSmsAsync ctx, userMobileNumber, messageToSend
  else
    yield sendTestSmsAsync ctx, userMobileNumber, messageToSend
  return code

checkCodeAsync = co.wrap (ctx, options) ->
  """Checks a code sent to a given number"""
  {
    developerEmail
    userMobileNumber
    code
    ip
    test
  } = options

  result = yield r.table('codes').filter({
    developerEmail
    userMobileNumber
    code
  }).filter(r.row('sentTime').gt(r.now().sub(CODE_LIFETIME_SECONDS)))
    .filter(r.not(r.row('used').default(false)))
    .filter(r.row('test').default(false).eq(test))
    .update({used: true, usedIp: ip})

  if result.errors > 0
    console.error "Database error checking code #{ code } for mobile number #{ userMobileNumber } for developer #{ developerEmail } from #{ ip }: #{ result.first_error }"

  if result.replaced > 0
    return true

  console.log "Failed attempt to confirm number #{ userMobileNumber } with code #{ code } for developer #{ developerEmail } from #{ ip }"
  yield r.table('failedAttempts').insert({
    developerEmail
    userMobileNumber
    code
    attemptTime: r.now()
    ip
  })
  return false

sendSmsAsync = co.wrap (ctx, userMobileNumber, message) ->
  """Sends an SMS to a given number"""

  try
    client = Twilio.getClient()
    yield client.promise.sendMessage
      to: userMobileNumber
      from: secret.twilio.fromNumber
      body: message
  catch error
    throwTwilioError ctx, error

sendTestSmsAsync = co.wrap (ctx, userMobileNumber, message) ->
  """Simulates sending an SMS to a given number without actually sending one"""

  try
    client = Twilio.getTestClient()
    yield client.promise.sendMessage
      to: userMobileNumber
      from: secret.twilio.testing.fromNumber
      body: message
  catch error
    throwTwilioError ctx, error

throwTwilioError = (ctx, error) ->
  ctx.throw error.status, error.message,
    twilioCode: error.code
    twilioMoreInfo: error.moreInfo

makeCode = (numberOfDigits) ->
  """Generates a new code `numberOfDigits` digits long"""

  digit = -> Math.floor Math.random() * 10
  code = (digit() for _ in [0...numberOfDigits]).join ''

exports.sendCodeAsync = sendCodeAsync
exports.checkCodeAsync = checkCodeAsync
