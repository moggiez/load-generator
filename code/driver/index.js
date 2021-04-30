"use strict";

const events = require("./events");
const uuid = require("uuid");
const short = require("short-uuid");

const hardLimit = 100;
const DEBUG = false;

exports.handler = function (event, context, callback) {
  const headers = {
    "Content-Type": "text/plain",
    "Access-Control-Allow-Origin": "*",
  };

  const response = (status, body, headers) => {
    const httpResponse = {
      statusCode: status,
      body: JSON.stringify(body),
      headers: headers,
    };
    callback(null, httpResponse);
  };

  if (DEBUG) {
    response(200, event, headers);
  }

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
    response(500, exc, headers);
  }
};
