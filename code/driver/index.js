"use strict";

const events = require("./events");
const config = require("./config");
const helpers = require("./lambda_helpers");
const auth = require("./cognitoAuth");
const uuid = require("uuid");
const short = require("short-uuid");

const hardLimit = 100;

exports.handler = function (event, context, callback) {
  const response = helpers.getResponseFn(callback);

  if (config.DEBUG) {
    response(200, event, config.headers);
  }

  const user = auth.getUserFromEvent(event);

  const body = JSON.parse(event.body);
  const detail = "steps" in body ? body.steps[0] : body;

  const usersCount = detail["users"];
  const userCallParams = { ...detail };
  delete userCallParams["users"];
  const shortUUIDTranslator = short();
  const loadtestId = shortUUIDTranslator.new();

  try {
    let i = 0;
    while (i < usersCount) {
      events.triggerUserCalls(
        loadtestId,
        shortUUIDTranslator.new(),
        userCallParams,
        response
      );
      i++;
    }
  } catch (exc) {
    response(500, exc, config.headers);
  }
};
