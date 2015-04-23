Codes = require '../codes/Codes'

assert = require 'assert'
co = require 'co'
fs = require 'fs'
instapromise = require 'instapromise'
{
  isBoolean
  isNaN
  isString
} = require 'lodash-node'
timeconstants = require 'timeconstants'
util = require 'util'

# This doesn't really validate e-mails but is a basic sanity check
EMAIL_REGEX = /.+\@.+\..+/
DEFAULT_NUMBER_OF_DIGITS = 6

exports.sendCodeAsync = (next) ->
  {
    developerEmail
    userMobileNumber
    message
    numberOfDigits
  } = @query

  validateStandardRequest @

  if numberOfDigits?
    numberOfDigits = parseInt numberOfDigits, 10
    if isNaN numberOfDigits
      @throw 400, "`numberOfDigits` must be a number"
    if numberOfDigits < 3
      @throw 400, "`numberOfDigits` must be at least 3"
    if numberOfDigits > 24
      @throw 400, "`numberOfDigits` must be 24 or less"
  else
    numberOfDigits = DEFAULT_NUMBER_OF_DIGITS

  receipt = yield Codes.sendCodeAsync @, {
    developerEmail
    userMobileNumber
    numberOfDigits
    message
    ip: @ip
  }

  @body = { userMobileNumber }

exports.checkCodeAsync = (next) ->
  {
    userMobileNumber
    developerEmail
    code
  } = @query

  validateStandardRequest @

  if not code?
    @throw 400, "`code` must be provided"
  if code.length < 3
    @throw 400, "`code` must be at least 3 digits long"
  if code.length > 24
    @throw 400, "`code` must be less than 24 characters long"

  validCode = yield Codes.checkCodeAsync @, {
    developerEmail
    userMobileNumber
    code
    ip: @ip
  }

  @body = { validCode }

validateStandardRequest = (ctx) ->
  """Validates `developerEmail` and `userMobileNumber`"""
  {
    developerEmail
    userMobileNumber
  } = ctx.query

  if not isString developerEmail
    ctx.throw 400, "`developerEmail` query parameter must be provided and be a string"

  if not developerEmail.match EMAIL_REGEX
    ctx.throw 400, "`developerEmail` doesn't look like an e-mail address!"

  if developerEmail.length < 3
    ctx.throw 400, "`developerEmail` must be at least 3 characters long"

  if developerEmail.length >= 256
    ctx.throw 400, "`developerEmail` must be less than 256 characters long"

  if not isString userMobileNumber
    ctx.throw 400, "`userMobileNumber` must be provided and be a string"

  if userMobileNumber.length < 5
    ctx.throw 400, "`userMobileNumber` must be at least 5 digits long"

  if userMobileNumber.length >= 100
    ctx.throw 400, "`userMobileNumber` must be less than 100 characters long"
