example =
  twilio:
    AccountSID: 'AC_YOUR_TWILIO_ACCOUNT_SID'
    AuthToken: 'YOUR_TWILIO_AUTH_TOKEN'
    fromNumber: '+1_YOUR_TWILIO_NUMBER_TO_SEND_CONFIRMATION_CODES_FROM'

  rethinkdb:
    discovery: false
    servers: [
      {host: 'localhost', port: 28015}
    ]
    db: 'digitimate'


try
  _secret = require './_secret'
  module.exports = _secret
catch err
  if err.message.match /^Cannot find module/
    console.error "Define a configuration file with your secret tokens for Twilio, your database, etc. in `./_secret.coffee`"
    module.exports = example
  else
    throw err
