getStatusAsync = (next) ->
  @type = 'json'
  @body = status: 'ok'

module.exports = getStatusAsync
