specialErrorPropertyNames = new Set([
  'message',
  'status',
  'statusCode',
  'expose',
])

formatApiErrors = (next) ->
  try
    yield next
    if @body?
      @body.err = null
  catch error
    if error.expose
      @status = error.status ? 500
      @body = createErrorResponseBody error
    else
      throw error

createErrorResponseBody = (error) ->
  body = err: error.message
  for field, value of error
    unless specialErrorPropertyNames.has field
      body[field] = value
  return body

module.exports = formatApiErrors
