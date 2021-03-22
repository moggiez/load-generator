"use strict";

const AWS = require("aws-sdk");
const version = "0.0.1"
const build = "13"

exports.handler = function (event, context, callback) {
  try {
    const eventbridge = new AWS.EventBridge();

    const result_event = {
      event: event,
      result: {
        action: null,
        status: 200,
        message: "Nothing was done."
      }
    }
    const params = {
      Entries: [
        {
          Source: "Worker User Call",
          DetailType: "Call Result",
          Detail: JSON.stringify(result_event),
          EventBusName: "moggiez-load-test",
        },
      ],
    };
    console.log("eventbridge", eventbridge);
    const result = eventbridge.putEvents(params, function (err, data) {
      if (err) {
        console.log("Error", err);
        callback(err, null);
      } else {
        callback(null, data.RuleArn);
      }
    });
  } catch (exc) {
    callback(exc, null);
  }
};
