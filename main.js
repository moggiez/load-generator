"use strict";

exports.handler = function (event, context, callback) {
  var response = {
    statusCode: 200,
    headers: {
      "Content-Type": "text/html; charset=utf-8",
    },
    body:
      "version: 1.0.0-8",
  };
  callback(null, response);
};
