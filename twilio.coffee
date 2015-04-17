twilio = require 'twilio'

secret = require './secret'
{
  AccountSID
  AuthToken
} = secret.twilio

module.exports = twilio AccountSID, AuthToken
