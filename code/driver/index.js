"use strict";
const helpers = require("moggies-lambda-helpers");
const auth = require("moggies-auth");

const handlers = require("./handlers");

const hardLimit = 100;

const DEBUG = false;

exports.handler = async function (event, context, callback) {
  const response = helpers.getResponseFn(callback);

  if (DEBUG) {
    response(200, event);
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
      response(500, "Internal server error.");
    }
  } else {
    response(403, "Not supported.");
  }
};
