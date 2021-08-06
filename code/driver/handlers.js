const events = require("./events");
const { HttpClient } = require("./httpClient");
const { JobsApiClient } = require("./jobsApiClient");

const loadtestStates = {
  STARTED: "Started",
  RUNNING: "Running",
  COMPLETED: "Completed",
  ABORTED: "Aborted",
};

const usersApiUrl = "https://users-api.moggies.io";
const loadtestsApiUrl = "https://loadtests-api.moggies.io";
const playbooksApiUrl = "https://playbooks-api.moggies.io";

exports.getLoadtest = async (user, loadtestId, response) => {
  const http = new HttpClient(user);

  try {
    const usersResponse = await http.get(`${usersApiUrl}/${user.id}`);
    if (
      usersResponse.status != 200 ||
      !("OrganisationId" in usersResponse.data)
    ) {
      response(404, "Not found.");
    } else {
      const orgId = usersResponse.data.OrganisationId;

      const loadtestResponse = await http.get(
        `${loadtestsApiUrl}/${orgId}/${loadtestId}`
      );
      if (loadtestResponse.status == 200) {
        const playbookId = loadtestResponse.data.PlaybookId;
        const playbookResponse = await http.get(
          `${playbooksApiUrl}/${orgId}/playbooks/${playbookId}`
        );
        return {
          loadtest: loadtestResponse.data,
          playbook: playbookResponse.data,
        };
      }
    }
  } catch (exc) {
    console.log("Error: " + exc);
    response(500, "Internal server error.");
  }
};

const setLoadtestState = async (loadtest, newState, http) => {
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
  return await http.put(
    `${loadtestsApiUrl}/${loadtest.OrganisationId}/${loadtest.LoadtestId}`,
    updated
  );
};

exports.runPlaybook = async (user, playbook, loadtest, response) => {
  const http = new HttpClient(user);
  const jobsApi = new JobsApiClient(user);

  const detail = playbook.Steps[0];
  const usersCount = detail["users"];
  const userCallParams = { ...detail };
  delete userCallParams["users"];

  const startResponse = await setLoadtestState(
    loadtest,
    loadtestStates.STARTED,
    http
  );

  const jobData = await jobsApi.createJob({});
  if (startResponse.status == 200) {
    try {
      let i = 0;
      let userInvertedIndex = usersCount - i;
      while (i < usersCount) {
        const taskData = await jobsApi.createTask(jobData.data.JobId, {});
        events.addUserCall(
          loadtest.OrganisationId,
          loadtest.LoadtestId,
          taskData.data.JobId,
          taskData.data.TaskId,
          user,
          userCallParams,
          userInvertedIndex
        ); // mark user index
        i++;
        userInvertedIndex = usersCount - i;
      }
      await events.triggerUserCalls();
      const setResponse = await setLoadtestState(
        loadtest,
        loadtestStates.RUNNING,
        http
      );
      response(200, setResponse.data);
    } catch (exc) {
      console.log("Error: " + exc);
      response(500, "Internal server error.");
    }
  } else {
    response(500, "Error starting loadtets.");
  }
};
