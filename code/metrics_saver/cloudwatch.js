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
  let metricsData = await Metrics.getMetricsData(params);
  metricsData = JSON.parse(JSON.stringify(metricsData));
  metricsData.Source = "DB";
  const data = await loadtest_metrics.get(loadtest.LoadtestId, metricName);
  if ("Item" in data) {
    console.log("Updates metric data.");
    loadtest_metrics.update(loadtest.LoadtestId, metricName, {
      MetricsData: metricsData,
    });
  } else {
    console.log("Inserts metric data.");
    loadtest_metrics.create(loadtest.LoadtestId, metricName, {
      MetricsData: metricsData,
    });
  }
};
