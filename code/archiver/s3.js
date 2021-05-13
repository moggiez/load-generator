"use strict";

const AWS = require("aws-sdk");
const BUCKET_SUCCESS = "moggiez-call-responses-success";
const BUCKET_FAILURE = "moggiez-call-responses-failure";

const buildKey = (eventId, customer, userId, date, prefix) => {
  const dateFormat = `${date.getUTCFullYear()}/${
    date.getUTCMonth() + 1
  }/${date.getUTCDate()}`;
  const fileName = `${prefix}-${customer}-${userId}-${eventId}.json`;
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
  const params = {
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

exports.saveSuccess = (event, onSuccess, onFailure) => {
  const key = buildKey(
    event.id,
    event.detail.customer,
    event.detail.request.userId,
    new Date(event.time),
    "success"
  );
  saveToS3(event, BUCKET_SUCCESS, key, onSuccess, onFailure);
};

exports.saveFailure = (event, onSuccess, onFailure) => {
  const key = buildKey(
    event.id,
    event.detail.customer,
    event.detail.request.userId,
    new Date(event.time),
    "failure"
  );
  saveToS3(event, BUCKET_FAILURE, key, onSuccess, onFailure);
};
