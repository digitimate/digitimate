rethinkdbdash = require 'rethinkdbdash'

secret = require './secret'

module.exports = r = rethinkdbdash secret.rethinkdb
