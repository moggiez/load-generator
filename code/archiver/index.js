"use strict";

const s3 = require("./s3");
const cw = require("./cloudwatch");
const eventTypes = require("./eventTypes");

exports.handler = function (event, context, callback) {
  const terminateSuccess = (msg) => {
    console.log(msg);
    callback(msg, null);
  };

  const terminateFailure = (err) => {
    console.log("Error", err);
    callback(null, err);
  };

  try {
    if (event["detail-type"] == eventTypes.WORKER_SUCCESS_EVENT_TYPE) {
      s3.saveSuccess(
        event,
        () => {
          cw.trackResponseTimeMetric(
            event.detail,
            (data) =>
              terminateSuccess(
                "Event written to S3 and tracker in CloudWatch metrics."
              ),
            (err) => terminateFailure(err)
          );
        },
        (err) => {
          cw.trackResponseTimeMetric(
            event.detail,
            (data) =>
              terminateSuccess(
                `Event NOT written to S3 (${err}) and tracker in CloudWatch metrics.`
              ),
            (err2) => terminateFailure(err2)
          );
        }
      );
    } else if (event["detail-type"] == eventTypes.WORKER_FAILURE_EVENT_TYPE) {
      s3.saveFailure(
        event,
        () => terminateSuccess("Wrote event to S3 successfully"),
        (err) => {
          terminateFailure(err);
        }
      );
    } else {
      const msg = `Wrong event routed to archive lambda: ${event["detail-type"]}`;
      terminateSuccess(msg);
    }
  } catch (exc) {
    terminateFailure(exc);
  }
};
