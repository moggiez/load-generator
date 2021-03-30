"use strict";

const AWS = require("aws-sdk");

exports.handler = function (event, context, callback) {
  try {
    const eventbridge = new AWS.EventBridge();
    const params = {
      Entries: [
        {
          Source: "Driver",
          DetailType: "User Calls",
          Detail: JSON.stringify(event),
          EventBusName: "moggiez-load-test",
        },
      ],
    };
    eventbridge.putEvents(params, function (err, data) {
      if (err) {
        callback(err, {
            statusCode: 500,
            body: err,
            headers: {'Content-Type': 'text/plain'}
        });
      } else {
        const message = {
          triggeredRule: data.RuleArn,
          message: "Successfully called Moggiez Driver"
        }
        callback(null, {
            statusCode: 200,
            body: JSON.stringify(message),
            headers: {'Content-Type': 'application/json'}
        });
      }
    });
  } catch (exc) {
    callback(exc, {
            statusCode: 500,
            body: err,
            headers: {'Content-Type': 'text/plain'}
    });
  }
};
