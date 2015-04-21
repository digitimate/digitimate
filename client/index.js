"use strict";

var request = require('request');

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
  "Returns the URL for making a `sendCode` call with the given args"
  _assertRequiredArgs(args, ['developerEmail', 'userMobileNumber']);
  return _makeUrl(module.exports.baseUrl, 'sendCode', args);
};

var checkCodeUrl = function (args) {
  "Returns the URL for making a `checkCode` call with the given args"
  _assertRequiredArgs(args, ['developerEmail', 'userMobileNumber', 'code']);
  return _makeUrl(module.exports.baseUrl, 'checkCode', args);
};

var _makeApiCallAsync = function (method, args) {
  return new Promise(function (resolve, reject) {
    var url;
    switch (method) {
      case 'sendCode':
        url = sendCodeUrl(args);
        break;
      case 'checkCode':
        url = checkCodeUrl(args);
        break;
    }
    request.post(url, {}, function (err, response, body) {
      if (err) {
        reject(err);
      } else {
        try {
          var responseObj = JSON.parse(body);
        } catch (e) {
          reject(e);
          return;
        }
        if (responseObj.success === false) {
          reject(new Error(responseObj.err || "Error response from server"));
        } else {
          resolve(responseObj);
        }
      }
    });
  });
};

var sendCodeAsync = function (args) {
  return _makeApiCallAsync('sendCode', args);
};

var checkCodeAsync = function (args) {
  return _makeApiCallAsync('checkCode', args);
};

module.exports = {
  __doc__: "A client for the digitimate phone number verification service",
  baseUrl: "http://digitimate.com/",
  sendCodeUrl: sendCodeUrl,
  checkCodeUrl: checkCodeUrl,
  sendCodeAsync: sendCodeAsync,
  checkCodeAsync: checkCodeAsync,
};
