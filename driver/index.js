"use strict";

const AWS = require("aws-sdk");
const version = "0.0.1";
const build = "13";

exports.handler = function (event, context, callback) {
  try {
    const eventbridge = new AWS.EventBridge();
    const params = {
      Entries: [
        {
          Source: "Driver Lambda",
          DetailType: "User Calls",
          Detail: JSON.stringify(event),
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
