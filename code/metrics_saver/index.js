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
    const hourDateString = new Date().toISOString().substring(0, 13);
    const loadtestsInPastHour = await loadtests.getBySecondaryIndex(
      "CreatedAtHourIndex",
      hourDateString
    );
    const data =
      "Items" in loadtestsInPastHour
        ? loadtestsInPastHour.Items
        : [loadtestsInPastHour.Item];

    data.forEach(async (el) => {
      try {
        const loadtest = await loadtests.get(el.OrganisationId, el.LoadtestId);
        await cw.saveMetricDataToDb(loadtest.Item, "ResponseTime");
        await setLoadtestMetricsSaved(loadtest.Item);
      } catch (errLd) {
        console.log(errLd);
      }
    });

    callback(null, "Success");
  } catch (err) {
    console.log(err);
    callback(err, null);
  }
};
