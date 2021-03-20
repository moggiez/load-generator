"use strict";

const version = "0.0.1"
const build = "13"
exports.handler = function (event, context, callback) {
  var response = {
    statusCode: 200,
    headers: {
      "Content-Type": "text/html; charset=utf-8",
    },
    body:
      {
        "version": version,
        "build": build
      }
  };
  callback(null, response);
};
