/**
 * A client for the Digitimate mobile phone number verification service
 *
 * See http://digitimate.com/ for more info
 *
 * Digitimate works like this:
 * - A user enters his/her phone number into your application
 * - You send an HTTP request to digitimate.com that includes the phone number and some other metadata
 * - Digitimate generates a random code that is SMSed to the phone number the user provided
 * - When the user gets the code, he/she enters into your application
 * - Your application makes an HTTP request to digitimate.com with both the phone number and the code
 * - Digimate will respond with whether the code was valid or not
 *
 * @providesModule digitimate
 */
 'use strict';

 var _makeUrl = function (baseUrl, method, args) {
   var keys = Object.keys(args);
   var terms = [];
   for (var i = 0; i < keys.length; i++) {
     var key = keys[i];
     var term = encodeURIComponent(key) + '=' + encodeURIComponent(args[key]);
     terms.push(term);
   }
   var url = baseUrl + method + '?' + (terms.join('&'));
   return url;
 };

 var _assertRequiredArgs = function (args, requiredArgsList) {
   var keys = Object.keys(requiredArgsList);
   for (var i = 0; i < keys.length; i++) {
     var key = requiredArgsList[i];
     if (args[key] == null) {
       throw new Error('Missing required argument: `' + key + '`');
     }
   }
 };

 var sendCodeUrl = function (args) {
   'Returns the URL for making a `sendCode` call with the given args'
   _assertRequiredArgs(args, ['developerEmail', 'userMobileNumber']);
   return _makeUrl(module.exports.baseUrl, 'sendCode', args);
 };

 var checkCodeUrl = function (args) {
   'Returns the URL for making a `checkCode` call with the given args'
   _assertRequiredArgs(args, ['developerEmail', 'userMobileNumber', 'code']);
   return _makeUrl(module.exports.baseUrl, 'checkCode', args);
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
     return fetch(url)
      .then((response) => response.text())
      .then((body) => {
       try {
         var responseObj = JSON.parse(body);
       } catch (e) {
         throw new Error('Did not get a valid JSON response from the server');
       }
       if (responseObj.err != null) {
         throw new Error(responseObj.err);
       } else {
         return responseObj;
       }

     });
 };

 var sendCodeAsync = function (args) {
   return _makeApiCallAsync('sendCode', args);
 };

 var checkCodeAsync = function (args) {
   return _makeApiCallAsync('checkCode', args).then((response) => response.validCode);
 };

 module.exports = {
   __doc__: 'A client for the digitimate phone number verification service',
   baseUrl: 'http://digitimate.com/',
   sendCodeUrl: sendCodeUrl,
   checkCodeUrl: checkCodeUrl,
   sendCodeAsync: sendCodeAsync,
   checkCodeAsync: checkCodeAsync,
 };
