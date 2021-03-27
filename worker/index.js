"use strict";

const AWS = require("aws-sdk");
const http = require('http');
const name = "Worker";

const makeRequest = (options, onSuccess, onError) => {
  const processResponse = res => {
    let buffer = "";
    res.on('data', chunk => buffer += chunk);
    res.on('end', () => onSuccess(res.statusCode, buffer));
  };
  const req = http.request(options, processResponse);
  req.on('error', e => onError(e.message));
  req.end();
}

const sendEvent = (eventbridge, eventParams, onSuccess, onFailure) => {
  console.log('Sending event', eventParams)
  eventbridge.putEvents(eventParams, (err, data) => { 
    if (err) {
      console.log('Failed sending events', err);
      onFailure(err);
    } else {
      onSuccess(data.ruleArn);
    }
  });
};

const buildEventParams = (source, type, payload) => {
  return {
    Entries: [
      {
        Source: source,
        DetailType: type,
        Detail: JSON.stringify(payload),
        EventBusName: "moggiez-load-test",
      },
    ],
  }
};

exports.handler = function (event, context, callback) {
  try {
    const eventbridge = new AWS.EventBridge();
    sendEvent(eventbridge, buildEventParams(name, "Worker Request Start", event), data => console.log(data), err => console.log(err));
    const request = event.request;
    const options = request.options;
    makeRequest(
      event.request.options,
      (status, data) => {
        const payload = {
          request: event.request,
          status: status,
          data: data
        }
        sendEvent(eventbridge, buildEventParams(name, "Worker Request Success", payload), data => callback(null, data), err => callback(err, null));
      },
      error => {
        const payload = {
          request: event.request,
          error: error
        }
        sendEvent(eventbridge, buildEventParams(name, "Worker Request Failure", payload), data => callback(null, data), err => callback(err, null));
      }
    );
  } catch (exc) {
    console.log('Error', exc);
    callback(exc, null);
  }
};