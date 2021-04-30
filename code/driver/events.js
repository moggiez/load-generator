"use strict";

const AWS = require("aws-sdk");
const eventbridge = new AWS.EventBridge();
const eventTypes = require("./eventTypes");

const EVENT_SOURCE = "Driver";
const EVENT_BUS_NAME = "moggiez-load-test";
const SUCCESS_MSG_HTTP_RESP = "Successfully called Moggiez Driver";

const headers = {
  "Content-Type": "text/plain",
  "Access-Control-Allow-Origin": "*",
};

const triggerUserCalls = (loadtestId, userId, eventParams, response) => {
  const params = {
    Entries: [
      {
        Source: EVENT_SOURCE,
        DetailType: eventTypes.USER_CALLS_EVENT_TYPE,
        Detail: JSON.stringify({
          ...eventParams,
          loadtestId: loadtestId,
          userId: userId,
        }),
        EventBusName: EVENT_BUS_NAME,
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
          message: SUCCESS_MSG_HTTP_RESP,
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
};

exports.triggerUserCalls = triggerUserCalls;
