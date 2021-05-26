"use strict";
const helpers = require("lambda_helpers");
const auth = require("cognitoAuth");

const events = require("./events");
const config = require("./config");
const handlers = require("./handlers");

const hardLimit = 100;

exports.handler = function (event, context, callback) {
  const response = helpers.getResponseFn(callback);

  if (config.DEBUG) {
    response(200, event, config.headers);
  }

  const user = auth.getUserFromEvent(event);
  const httpMethod = event.httpMethod;
  const pathParameters = event.pathParameters;
  const pathParams =
    pathParameters != null && "proxy" in pathParameters && pathParameters.proxy
      ? pathParameters.proxy.split("/")
      : [];
  const loadtestId = pathParams[0];
  if (httpMethod == "POST") {
    //const detail = "steps" in body ? body.steps[0] : body;
    handlers
      .getLoadtest(user, loadtestId, response)
      .then((data) => {
        const playbook = JSON.parse(data.playbook.Playbook);
        handlers.runPlaybook(user, playbook, data.loadtest, response);
      })
      .catch((err) => {
        console.log("getLoadtest error", err);
        response(500, "Internal server err", config.headers);
      });
  } else {
    response(403, "Not supported.", config.headers);
  }
};
