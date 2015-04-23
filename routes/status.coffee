getStatusAsync = (next) ->
  @type = 'json'
  @body = status: 'ok'
  yield next

module.exports = getStatusAsync
