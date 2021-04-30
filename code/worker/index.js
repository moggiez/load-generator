"use strict";

const requests = require("./requests");
const events = require("./events");
const eventTypes = require("./eventTypes");

const terminateWithSuccess = (callback, data) => {
  callback(null, data);
};

const terminateWithFailure = (callback, err) => {
  callback(err, null);
};

const onRequestSuccess = (request, callback, result, terminate) => {
  const payload = {
    request: request,
    customer: "default",
    result: result,
  };
  events.sendEvent(
    eventTypes.WORKER_SUCCESS_EVENT_TYPE,
    payload,
    (data) => (terminate ? terminateWithSuccess(callback, data) : null),
    (err) => terminateWithFailure(callback, err)
  );
};

const onRequestFailure = (request, callback, error) => {
  const payload = {
    request: request,
    customer: "default",
    error: error,
  };
  events.sendEvent(
    eventTypes.WORKER_FAILURE_EVENT_TYPE,
    payload,
    (data) => terminateWithSuccess(callback, data),
    (err) => terminateWithFailure(callback, err)
  );
};

exports.handler = function (event, context, callback) {
  try {
    if ("request" in event.detail) {
      const request = event.detail.request;
      const options = request.options;
      requests.makeRequest(
        options,
        (status, data) =>
          onRequestSuccess(request, callback, status, data, true),
        (error) => onRequestFailure(request, callback, error)
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
              callback,
              {
                status: response.status,
                responseTime: response.responseTime,
                startedAt: new Date(
                  response.config.meta.requestStartedAt
                ).toISOString(),
                endedAt: new Date(response.requestEndedAt).toISOString(),
              },
              iteration >= maxIterations
            ),
          (err) => onRequestFailure(event.detail, callback, err)
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
