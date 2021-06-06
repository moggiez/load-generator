"use strict";

const AWS = require("aws-sdk");
const CloudWatch = new AWS.CloudWatch({ apiVersion: "2010-08-01" });
const metricsHelpers = require("metrics");
const db = require("db");
const loadtest_metrics = new db.Table(db.tableConfigs.loadtest_metrics);

const Metrics = new metricsHelpers.Metrics(CloudWatch);

exports.saveMetricDataToDb = async (loadtest, metricName) => {
  const params = Metrics.generateGetMetricsDataParamsForLoadtest(
    loadtest,
    metricName
  );
  const metricsData = await Metrics.getMetricsData(params);
  const data = await loadtest_metrics.get(loadtest.LoadtestId, metricName);
  if ("Item" in data) {
    loadtest_metrics.update(loadtest.LoadtestId, metricName, {
      Data: metricsData,
    });
  } else {
    loadtest_metrics.create(loadtest.LoadtestId, metricName, {
      Data: metricsData,
    });
  }
};
