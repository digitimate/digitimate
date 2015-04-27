twilio = require 'twilio'

secret = require '../secret'
{
  AccountSID: accountSid
  AuthToken: authToken
  testing:
    AccountSID: testAccountSid
    AuthToken: testAuthToken
} = secret.twilio

_client = null
_testClient = null

exports.getClient = ->
  _client ?= twilio accountSid, authToken

exports.getTestClient = ->
  _testClient ?= twilio testAccountSid, testAuthToken
