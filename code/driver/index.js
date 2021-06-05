"use strict";
const helpers = require("lambda_helpers");
const auth = require("cognitoAuth");

const events = require("./events");
const config = require("./config");
const handlers = require("./handlers");

const hardLimit = 100;

exports.handler = async function (event, context, callback) {
  const response = helpers.getResponseFn(callback);

  if (config.DEBUG) {
    response(200, event, config.headers);
  }

  const user = auth.getUserFromEvent(event);
  const request = helpers.getRequestFromEvent(event);
  const loadtestId = request.getPathParamAtIndex(0, null);

  if (request.httpMethod == "POST") {
    try {
      const { loadtest, playbook } = await handlers.getLoadtest(
        user,
        loadtestId,
        response
      );
      await handlers.runPlaybook(user, playbook, loadtest, response);
    } catch (exc) {
      console.log(exc);
      response(500, "Internal server error.", config.headers);
    }
  } else {
    response(403, "Not supported.", config.headers);
  }
};
