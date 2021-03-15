"use strict";
const AWS = require('aws-sdk');
exports.handler = function (event, context, callback) {
    try {
        const eventbridge = new AWS.EventBridge();
        const detail = {
            a:"test",
            b:"me"
        }
        const params = { 
            Entries: [
                {
                    Source: "Driver Lambda",
                    DetailType: "Moggiez Simple Call",
                    Detail: JSON.stringify(detail),
                    EventBusName: "loadtest"
                }
            ]
        };
        console.log('eventbridge', eventbridge)
        const result = eventbridge.putEvents(params, function(err, data) {
          if (err) {
            console.log("Error", err);
            callback(err, null);
          } else {
            console.log("Success", data.RuleArn);
            callback(null, result);
          }
        });
        callback(null, JSON.stringify(eventbridge));
    } catch (exc) {
        callback(exc, null);
    }
};
