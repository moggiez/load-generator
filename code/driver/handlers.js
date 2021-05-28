const db = require("db");
const uuid = require("uuid");
const short = require("short-uuid");
const config = require("./config");
const events = require("./events");

const organisations = new db.Table(db.tableConfigs.organisations);
const loadtests = new db.Table(db.tableConfigs.loadtests);
const playbooks = new db.Table(db.tableConfigs.playbooks);

const loadtestStates = {
  STARTED: "Started",
  RUNNING: "Running",
  COMPLETED: "Completed",
  ABORTED: "Aborted",
};

exports.getLoadtest = (user, loadtestId, response) => {
  const onError = (e) => {
    response(500, "Internal server error.", config.headers);
  };
  return new Promise((resolve, reject) => {
    organisations
      .getBySecondaryIndex("UserOrganisations", user.id)
      .then((orgData) => {
        if (orgData.Items.length == 0) {
          response(404, "Not found.", config.headers);
        } else {
          const orgId = orgData.Items[0].OrganisationId;
          loadtests
            .get(orgId, loadtestId)
            .then((loadtestData) => {
              const playbookId = loadtestData.Item.PlaybookId;
              playbooks
                .get(orgId, playbookId)
                .then((playbookData) => {
                  resolve({
                    loadtest: loadtestData.Item,
                    playbook: playbookData.Item,
                  });
                })
                .catch((err) => onError(err));
            })
            .catch((err) => onError(err));
        }
      })
      .catch((err) => {
        console.log("Unable to fetch user organisations.", err);
        onError(err);
      });
  });
};

const setLoadtestState = (loadtest, newState) => {
  const updated = { ...loadtest };
  delete updated.OrganisationId;
  delete updated.LoadtestId;
  updated["CurrentState"] = newState;
  if (newState == loadtestStates.STARTED) {
    updated["StartDate"] = new Date().toISOString();
  } else if (
    newState == loadtestStates.COMPLETED ||
    newState == loadtestStates.ABORTED
  ) {
    updated["EndDate"] = new Date().toISOString();
  }

  return loadtests.update(
    loadtest.OrganisationId,
    loadtest.LoadtestId,
    updated
  );
};

exports.runPlaybook = (user, playbook, loadtest, response) => {
  const detail = playbook.steps[0];
  const usersCount = detail["users"];
  const userCallParams = { ...detail };
  delete userCallParams["users"];

  setLoadtestState(loadtest, loadtestStates.STARTED);

  try {
    let i = 0;
    while (i < usersCount) {
      events.addUserCall(loadtest.LoadtestId, user.id, userCallParams);
      i++;
    }

    events
      .triggerUserCalls()
      .then((data) => {
        setLoadtestState(loadtest, loadtestStates.RUNNING)
          .catch((err) => console.log(err))
          .finally((data) => response(200, data, config.headers));
      })
      .catch((err) => {
        console.log(err);
        response(500, err, config.headers);
      });
  } catch (exc) {
    console.log(exc);
    response(500, exc, config.headers);
  }
};
