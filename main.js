"use strict";

exports.handler = function (event, context, callback) {
  var response = {
    statusCode: 200,
    headers: {
      "Content-Type": "text/html; charset=utf-8",
    },
    body:
      "<p>Hello world! TEST 1.0.2</p><div id='event'>" +
      JSON.stringify(event) +
      "</div><div id='context'>" +
      JSON.stringify(context) +
      "</div>",
  };
  callback(null, response);
};
