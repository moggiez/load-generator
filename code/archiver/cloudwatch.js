"use strict";

const AWS = require("aws-sdk");
const CloudWatch = new AWS.CloudWatch({ apiVersion: "2010-08-01" });

const STORAGE_RESOLUTION_HIGH = 1;
const STORAGE_RESOLUTION_REGULAR = 60;

const putMetric = (params, onSuccess, onFailure) => {
  CloudWatch.putMetricData(params, function (err, data) {
    if (err) {
      onFailure(err);
    } else {
      onSuccess(data);
    }
  });
};

exports.trackResponseTimeMetric = (workerEventDetail, onSuccess, onFailure) => {
  const customer = workerEventDetail.request.customerId;
  const loadtestId = workerEventDetail.request.loadtestId;
  const params = {
    MetricData: [
      {
        MetricName: "ResponseTime",
        Dimensions: [
          {
            Name: "LOADTEST_ID",
            Value: loadtestId,
          },
          {
            Name: "CUSTOMER",
            Value: customer,
          },
          {
            Name: "USER_ID",
            Value: workerEventDetail.request.userId,
          },
          {
            Name: "STATUS",
            Value: workerEventDetail.result.status.toString(),
          },
        ],
        Timestamp: workerEventDetail.result.endedAt,
        Unit: "Milliseconds",
        Value: workerEventDetail.result.responseTime,
        StorageResolution: STORAGE_RESOLUTION_HIGH,
      },
    ],
    Namespace: `moggies.io/Loadtests`,
  };
  putMetric(params, onSuccess, onFailure);
};

exports.saveMetricsToDB = (loadtest) => {};
