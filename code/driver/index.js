"use strict";

const AWS = require("aws-sdk");

const hardLimit = 100;
const DEBUG = false;

exports.handler = function (event, context, callback) {
  const headers = {
    "Content-Type": "text/plain",
    "Access-Control-Allow-Origin": "*",
  };

  const response = (status, body, headers) => {
    const httpResponse = {
      statusCode: status,
      body: JSON.stringify(body),
      headers: headers,
    };
    callback(null, httpResponse);
  };

  if (DEBUG) {
    response(200, event, headers);
  }

  const body = JSON.parse(event.body);
  const detail = "steps" in body ? body.steps[0] : body;
  try {
    const eventbridge = new AWS.EventBridge();
    const params = {
      Entries: [
        {
          Source: "Driver",
          DetailType: "User Calls",
          Detail: JSON.stringify(detail),
          EventBusName: "moggiez-load-test",
        },
      ],
    };
    eventbridge.putEvents(params, function (err, data) {
      if (err) {
        response;
        500, err, headers;
      } else {
        if (data.FailedEntryCount == 0) {
          const message = {
            triggeredRule: data.RuleArn,
            message: "Successfully called Moggiez Driver",
          };
          response(200, message, headers);
        } else {
          const errPayload = {
            data: data,
          };
          response(500, errPayload, headers);
        }
      }
    });
  } catch (exc) {
    response(500, exc, headers);
  }
};
