"use strict";

const AWS = require("aws-sdk");
const name = "Archiver";
const bucketSuccess = "moggiez-call-responses-success";
const bucketFailure = "moggiez-call-responses-failure";

const buildKey = (id, customer, date, prefix) => {
  const dateFormat = `${date.getUTCFullYear()}/${
    date.getUTCMonth() + 1
  }/${date.getUTCDate()}`;
  const fileName = `${prefix}-${customer}-${id}.json`;
  return `${customer}/${dateFormat}/${fileName}`;
};

const saveToS3 = (event, bucket, key, onSuccess, onFailure) => {
  const s3 = new AWS.S3();
  const data = {
    ...event.detail,
    date: event.time,
    id: event.id,
    region: event.region,
    source: event.source,
  };
  var params = {
    Bucket: bucket,
    Key: key,
    Body: JSON.stringify(data),
  };
  s3.putObject(params, function (err, data) {
    if (err) {
      onFailure(err);
    } else {
      onSuccess();
    }
  });
};

exports.handler = function (event, context, callback) {
  try {
    let bucket = "unknown";
    let key = "unknown";
    if (event["detail-type"] == "Worker Request Success") {
      bucket = bucketSuccess;
      key = buildKey(
        event.id,
        event.detail.customer,
        new Date(event.time),
        "success"
      );
    } else if (event["detail-type"] == "Worker Request Failure") {
      bucket = bucketFailure;
      key = buildKey(
        event.id,
        event.detail.customer,
        new Date(event.time),
        "failure"
      );
    } else {
      const msg = `Wrong event routed to archive lambda: ${event["detail-type"]}`;
      console.log(msg);
      callback(msg, null);
    }
    saveToS3(
      event,
      bucket,
      key,
      () => callback("Wrote event to S3 successfully", null),
      (err) => {
        console.log("Error", err);
        callback(null, err);
      }
    );
  } catch (exc) {
    console.log("Error", exc);
    callback(exc, null);
  }
};
