"use strict";

const AWS = require("aws-sdk");

exports.handler = function (event, context, callback) {
  const headers = {
    'Content-Type': 'text/plain',
    'Access-Control-Allow-Origin': '*'
  }
  const detail = event.body;
  try {
    const eventbridge = new AWS.EventBridge();
    const params = {
      Entries: [
        {
          Source: "Driver",
          DetailType: "User Calls",
          Detail: detail,
          EventBusName: "moggiez-load-test",
        },
      ],
    };
    eventbridge.putEvents(params, function (err, data) {
      if (err) {
        callback(err, {
            statusCode: 500,
            body: err,
            headers: headers
        });
      } else {
        if (data.FailedEntryCount == 0) {
          const message = {
            triggeredRule: data.RuleArn,
            message: "Successfully called Moggiez Driver"
          }
          callback(null, {
              statusCode: 200,
              body: JSON.stringify(message),
              headers: headers
          });
        } else {
          const errPayload = {
            data: data
          }
          callback(null, {
              statusCode: 500,
              body: JSON.stringify(errPayload),
              headers: headers
          });
        }
      }
    });
  } catch (exc) {
    callback(exc, {
            statusCode: 500,
            body: exc,
            headers: headers
    });
  }
};
