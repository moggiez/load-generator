"use strict";

const AWS = require("aws-sdk");
const requests = require("./requests");
const events = require("./events");
const name = "Worker";

const terminateWithSuccess = (callback, data) => {
  callback(null, data);
};

const terminateWithFailure = (callback, err) => {
  callback(err, null);
};

const onRequestSuccess = (
  request,
  eventbridge,
  callback,
  status,
  data,
  terminate
) => {
  const payload = {
    request: request,
    customer: "default",
    status: status,
    responseTime: data,
  };
  events.sendEvent(
    eventbridge,
    events.buildEventParams(name, "Worker Request Success", payload),
    (data) => (terminate ? terminateWithSuccess(callback, data) : null),
    (err) => terminateWithFailure(callback, err)
  );
};

const onRequestFailure = (request, eventbridge, callback, error) => {
  const payload = {
    request: request,
    customer: "default",
    error: error,
  };
  events.sendEvent(
    eventbridge,
    events.buildEventParams(name, "Worker Request Failure", payload),
    (data) => terminateWithSuccess(callback, data),
    (err) => terminateWithFailure(callback, err)
  );
};

exports.handler = function (event, context, callback) {
  try {
    const eventbridge = new AWS.EventBridge();

    if ("request" in event.detail) {
      const request = event.detail.request;
      const options = request.options;
      requests.makeRequest(
        options,
        (status, data) =>
          onRequestSuccess(request, eventbridge, callback, status, data, true),
        (error) => onRequestFailure(request, eventbridge, callback, error)
      );
    } else {
      const requestOptions = event.detail.requestOptions;
      const waitBetweenRequests = event.detail.wait * 1000;
      const repeatRequest = event.detail.repeats;
      const doAndWait = (iteration, maxIterations, wait) => {
        requests.makeRequestAxiosGet(
          requestOptions,
          (response) =>
            onRequestSuccess(
              event.detail,
              eventbridge,
              callback,
              response.status,
              response.responseTime,
              iteration >= maxIterations
            ),
          (err) => onRequestFailure(event.detail, eventbridge, callback, err)
        );

        const curry = () => doAndWait(iteration + 1, maxIterations, wait);

        if (iteration + 1 < maxIterations) {
          setTimeout(curry, wait);
        }
      };
      doAndWait(0, repeatRequest, waitBetweenRequests);
    }
  } catch (exc) {
    terminateWithFailure(callback, exc);
  }
};
