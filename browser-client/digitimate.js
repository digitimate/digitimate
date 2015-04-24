window.Digitimate = (function () {
  "use strict";

  var postAsync = function (url) {
    return new Promise(function (fulfill, reject) {
      var request = new XMLHttpRequest();
      request.open('POST', url, true);

      request.onload = function() {
        var resp = request.responseText;
        var data;
        try {
          data = JSON.parse(resp);
        } catch (e) {
          data = {err: "Couldn't parse response"};
        }
        if (request.status >= 200 && request.status < 400) {
          fulfill(data);
        } else {
          var err = new Error(data.err || "Unknown error");
          err.status = request.status;
          err.data = data;
          reject(err);
        }
      };

      request.onerror = function () {
        // There was a connection error of some sort
        reject(new Error("Error sending request to Digitimate server"));
      };

      request.send();

    });
  };

  var _makeUrl = function (baseUrl, method, args) {
    var keys = Object.keys(args);
    var terms = [];
    for (var i = 0; i < keys.length; i++) {
      var key = keys[i];
      var term = encodeURIComponent(key) + '=' + encodeURIComponent(args[key]);
      terms.push(term);
    }
    var url = baseUrl + method + "?" + (terms.join("&"));
    return url;
  };

  var _assertRequiredArgs = function (args, requiredArgsList) {
    var keys = Object.keys(requiredArgsList);
    for (var i = 0; i < keys.length; i++) {
      var key = requiredArgsList[i];
      if (args[key] == null) {
        throw new Error("Missing required argument: `" + key + "`");
      }
    }
  };

  var sendCodeUrl = function (args) {
    _assertRequiredArgs(args, ['developerEmail', 'userMobileNumber']);
    var baseUrl = window.Digitimate.baseUrl;
    return _makeUrl(baseUrl, 'sendCode', args);
  };

  var checkCodeUrl = function (args) {
    _assertRequiredArgs(args, ['developerEmail', 'userMobileNumber', 'code']);
    var baseUrl = window.Digitimate.baseUrl;
    return _makeUrl(baseUrl, 'checkCode', args);
  };

  var _makeApiCallAsync = function (method, args) {
    var url;
    switch (method) {
      case 'sendCode':
        url = sendCodeUrl(args);
        break;
      case 'checkCode':
        url = checkCodeUrl(args);
        break;
    }
    return postAsync(url);
  };

  var sendCodeAsync = function (args) {
    return _makeApiCallAsync("sendCode", args);
  };

  var checkCodeAsync = function (args) {
    return _makeApiCallAsync("checkCode", args);
  };

  return {
    baseUrl: "http://digitimate.com/",
    sendCodeUrl: sendCodeUrl,
    checkCodeUrl: checkCodeUrl,
    sendCodeAsync: sendCodeAsync,
    checkCodeAsync: checkCodeAsync,
    postAsync: postAsync,
  };

})();
