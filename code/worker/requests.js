"use strict";

const http = require("http");
const axios = require("axios");

axios.interceptors.request.use((x) => {
  x.meta = x.meta || {};
  x.meta.requestStartedAt = new Date().getTime();
  return x;
});

axios.interceptors.response.use((x) => {
  x.requestEndedAt = new Date().getTime();
  x.responseTime = new Date().getTime() - x.config.meta.requestStartedAt;
  return x;
});

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

const makeRequestAxiosGet = async (options) => {
  const url = `${options.protocol}://${options.hostname}${getPortString(
    options
  )}/${options.path}`;
  return axios.get(url);
};

exports.makeRequest = makeRequest;
exports.makeRequestAxiosGet = makeRequestAxiosGet;
