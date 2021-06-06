"use strict";

const AWS = require("aws-sdk");

exports.saveToS3 = async (event, bucket, key) => {
  return new Promise((resolve, reject) => {
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
        reject(err);
      } else {
        resolve();
      }
    });
  });
};
