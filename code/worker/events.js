"use strict";

const AWS = require("aws-sdk");
const eventbridge = new AWS.EventBridge();

const EVENT_BUS_NAME = "moggiez-load-test";
const EVENT_SOURCE = "Worker";

const buildEventParams = (type, payload) => {
  return {
    Entries: [
      {
        Source: EVENT_SOURCE,
        DetailType: type,
        Detail: JSON.stringify(payload),
        EventBusName: EVENT_BUS_NAME,
      },
    ],
  };
};

const sendEvent = (type, payload, onSuccess, onFailure) => {
  const eventParams = buildEventParams(type, payload);
  eventbridge.putEvents(eventParams, (err, data) => {
    if (err) {
      onFailure(err);
    } else {
      onSuccess(data.ruleArn);
    }
  });
};

exports.sendEvent = sendEvent;
