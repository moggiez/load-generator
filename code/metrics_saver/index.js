"use strict";

const s3 = require("./s3");
const cw = require("./cloudwatch");
const db = require("db");
const loadtests = new db.Table(db.tableConfigs.loadtests);

const setLoadtestMetricsSaved = async (loadtest) => {
  const updated = { ...loadtest };
  delete updated.OrganisationId;
  delete updated.LoadtestId;
  updated["MetricsSavedDate"] = new Date().toISOString();

  return await loadtests.update(
    loadtest.OrganisationId,
    loadtest.LoadtestId,
    updated
  );
};

exports.handler = async function (event, context, callback) {
  try {
    await s3.saveToS3(event, "moggiez-call-responses-failure", event.id);

    const hourDateString = new Date().toISOString().substring(0, 13);
    const loadtestsInPastHour = await loadtests.getBySecondaryIndex(
      "CreatedAtHour",
      hourDateString
    );
    const data =
      "Items" in loadtestsInPastHour
        ? loadtestsInPastHour.Items
        : [loadtestsInPastHour.Item];

    data.forEach(async (loadtest) => {
      await cw.saveMetricDataToDb(loadtests, "ResponseTime");
      await setLoadtestMetricsSaved(loadtest);
    });

    callback("Success", null);
  } catch (err) {
    console.log(err);
    callback(null, err);
  }
};
