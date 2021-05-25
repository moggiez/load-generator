const db = require("db");
const uuid = require("uuid");
const short = require("short-uuid");
const config = require("./config");
const events = require("./events");

const organisations = new db.Table(db.tableConfigs.organisations);
const loadtests = new db.Table(db.tableConfigs.loadtests);
const playbooks = new db.Table(db.tableConfigs.playbooks);

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

exports.go = (detail, response) => {
  const usersCount = detail["users"];
  const userCallParams = { ...detail };
  delete userCallParams["users"];
  const shortUUIDTranslator = short();
  const loadtestId = shortUUIDTranslator.new();

  try {
    let i = 0;
    while (i < usersCount) {
      events.triggerUserCalls(
        loadtestId,
        shortUUIDTranslator.new(),
        userCallParams,
        response
      );
      i++;
    }
  } catch (exc) {
    response(500, exc, config.headers);
  }
};
