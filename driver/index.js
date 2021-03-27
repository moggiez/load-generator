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
    console.log("eventbridge", eventbridge);
    eventbridge.putEvents(params, function (err, data) {
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
