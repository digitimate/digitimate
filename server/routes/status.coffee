getStatusAsync = (next) ->
  @body = status: 'ok'
  yield return

module.exports = getStatusAsync
