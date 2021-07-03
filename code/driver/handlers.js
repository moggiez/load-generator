const db = require("moggies-db");
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

exports.getLoadtest = async (user, loadtestId, response) => {
  try {
    const orgData = await organisations.getBySecondaryIndex(
      "UserOrganisations",
      user.id
    );
    if (orgData.Items.length == 0) {
      response(404, "Not found.", config.headers);
    } else {
      const orgId = orgData.Items[0].OrganisationId;
      const loadtestData = await loadtests.get(orgId, loadtestId);
      const playbookId = loadtestData.Item.PlaybookId;
      const playbookData = await playbooks.get(orgId, playbookId);
      return {
        loadtest: loadtestData.Item,
        playbook: playbookData.Item,
      };
    }
  } catch (exc) {
    console.log(exc);
    response(500, "Internal server error.", config.headers);
  }
};

const setLoadtestState = async (loadtest, newState) => {
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

  return await loadtests.update(
    loadtest.OrganisationId,
    loadtest.LoadtestId,
    updated
  );
};

exports.runPlaybook = async (user, playbook, loadtest, response) => {
  const detail = playbook.Steps[0];
  const usersCount = detail["users"];
  const userCallParams = { ...detail };
  delete userCallParams["users"];

  await setLoadtestState(loadtest, loadtestStates.STARTED);

  try {
    let i = 0;
    let userInvertedIndex = usersCount - i;
    while (i < usersCount) {
      events.addUserCall(
        loadtest.OrganisationId,
        loadtest.LoadtestId,
        user.id,
        userCallParams,
        userInvertedIndex
      ); // mark user index
      i++;
      userInvertedIndex = usersCount - i;
    }
    await events.triggerUserCalls();
    const data = await setLoadtestState(loadtest, loadtestStates.RUNNING);
    response(200, data, config.headers);
  } catch (exc) {
    console.log(exc);
    response(500, "Internal server error.", config.headers);
  }
};
