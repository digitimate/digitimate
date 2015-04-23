require 'instapromise'

fs = require 'fs'
path = require 'path'

_cachedHtml = null

homepageAsync = (next) ->
  _cachedHtml ?= yield readHtmlAsync @state.config
  @type = 'text/html; charset=utf-8'
  @body = _cachedHtml

  if process.env.NODE_ENV isnt 'production'
    _cachedHtml = null

  yield next

readHtmlAsync = (config) ->
  htmlPath = path.join __dirname, '../site/homepage.html'
  html = yield fs.promise.readFile htmlPath, 'utf8'

  if config.googleAnalytics?.trackingId?
    googleAnalytics = """
      <script>
        (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
        (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
        m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
        })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

        ga('create', #{ JSON.stringify config.googleAnalytics.trackingId }, 'auto');
        ga('send', 'pageview');
      </script>
    """
    html = html.replace '<!-- Google Analytics -->', googleAnalytics
  return html

module.exports = homepageAsync
