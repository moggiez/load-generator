"use strict";

const AWS = require("aws-sdk");
const http = require("http");
const axios = require("axios");
const name = "Worker";

const makeRequest = (options, onSuccess, onError) => {
  const processResponse = (res) => {
    let buffer = "";
    res.on("data", (chunk) => (buffer += chunk));
    res.on("end", () => onSuccess(res.statusCode, buffer));
  };
  const req = http.request(options, processResponse);
  req.on("error", (e) => onError(e.message));
  req.end();
};

const getPortString = (options) => {
  const portString = "";
  if (options.protocol.toLowerCase() == "http" && options.port != 80) {
    portString = `:${options.port}`;
  }
  if (options.protocol.toLowerCase() == "https" && options.port != 443) {
    portString = `:${options.port}`;
  }
  return portString;
};

const makeRequestAxiosGet = (options, onSuccess, onError) => {
  const url = `${options.protocol}://${options.hostname}${getPortString(
    options
  )}/${options.path}`;
  axios
    .get(url)
    .then((response) => onSuccess(response))
    .catch((error) => onError(error));
};

const sendEvent = (eventbridge, eventParams, onSuccess, onFailure) => {
  console.log("Sending event", eventParams);
  eventbridge.putEvents(eventParams, (err, data) => {
    if (err) {
      console.log("Failed sending events", err);
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
  };
};

const onRequestSuccess = (request, eventbridge, callback, status, data) => {
  const payload = {
    request: request,
    customer: "default",
    status: status,
    data: data,
  };
  sendEvent(
    eventbridge,
    buildEventParams(name, "Worker Request Success", payload),
    (data) => callback(null, data),
    (err) => callback(err, null)
  );
};

const onRequestFailure = (request, eventbridge, callback, error) => {
  const payload = {
    request: request,
    customer: "default",
    error: error,
  };
  sendEvent(
    eventbridge,
    buildEventParams(name, "Worker Request Failure", payload),
    (data) => callback(null, data),
    (err) => callback(err, null)
  );
};

exports.handler = function (event, context, callback) {
  try {
    const eventbridge = new AWS.EventBridge();

    if ("request" in event.detail) {
      const request = event.detail.request;
      const options = request.options;
      makeRequest(
        options,
        (status, data) =>
          onRequestSuccess(request, eventbridge, callback, status, data),
        (error) => onRequestFailure(request, eventbridge, callback, error)
      );
    } else {
      let i = 0;
      while (i < event.detail.repeats) {
        makeRequestAxiosGet(
          event.detail.requestOptions,
          (response) =>
            onRequestSuccess(
              event.detail,
              eventbridge,
              callback,
              response.status,
              response.data
            ),
          (error) =>
            onRequestFailure(event.detail, eventbridge, callback, error)
        );
        i++;
        // Sleep event.detail.wait here
      }
    }
  } catch (exc) {
    console.log("Error", exc);
    callback(exc, null);
  }
};
