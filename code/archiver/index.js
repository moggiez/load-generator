"use strict";

const s3 = require("./s3");
const eventTypes = require("./eventTypes");

exports.handler = function (event, context, callback) {
  try {
    if (event["detail-type"] == eventTypes.WORKER_SUCCESS_EVENT_TYPE) {
      s3.saveSuccess(
        event,
        () => callback("Wrote event to S3 successfully", null),
        (err) => {
          console.log("Error", err);
          callback(null, err);
        }
      );
    } else if (event["detail-type"] == eventTypes.WORKER_FAILURE_EVENT_TYPE) {
      s3.saveFailure(
        event,
        () => callback("Wrote event to S3 successfully", null),
        (err) => {
          console.log("Error", err);
          callback(null, err);
        }
      );
    } else {
      const msg = `Wrong event routed to archive lambda: ${event["detail-type"]}`;
      console.log(msg);
      callback(msg, null);
    }
  } catch (exc) {
    console.log("Error", exc);
    callback(exc, null);
  }
};
