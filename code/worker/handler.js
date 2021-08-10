const { TasksApiClient } = require("./tasksApiClient");
const events = require("./events");
const eventTypes = require("./eventTypes");
const requests = require("./requests");

class Handler {
  constructor(event, callback) {
    this.tasksApi = new TasksApiClient(event.detail.user);
    this.callback = callback;
    this.event = event;
    this.results = [];
    this.errors = [];
  }

  async terminateWithSuccess(data) {
    await this.tasksApi.updateTask(
      this.event.detail.jobId,
      this.event.detail.taskId,
      "COMPLETED",
      { results: this.results },
      { errors: this.errors }
    );
    this.callback(null, data);
  }

  async terminateWithFailure(err) {
    await this.tasksApi.updateTask(
      this.event.detail.jobId,
      this.event.detail.taskId,
      "ERROR",
      null,
      err
    );
    this.callback(err, null);
  }

  async onRequestSuccess(request, result, terminate) {
    this.results.push(result);
    const payload = {
      request: request,
      result: result,
      wasUserLastRequest: terminate,
    };
    events.sendEvent(
      eventTypes.WORKER_SUCCESS_EVENT_TYPE,
      payload,
      async (data) =>
        terminate ? await this.terminateWithSuccess(data) : null,
      async (err) => await this.terminateWithFailure(err)
    );
  }

  async onRequestFailure(request, error, terminate) {
    this.errors.push(error);
    const payload = {
      request: request,
      error: error,
    };
    events.sendEvent(
      eventTypes.WORKER_FAILURE_EVENT_TYPE,
      payload,
      async (data) =>
        terminate ? await this.terminateWithSuccess(data) : null,
      async (err) => await this.terminateWithFailure(err)
    );
  }

  _sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  async _doAndWait(iteration, requestOptions, maxIterations, wait) {
    try {
      const response = await requests.makeRequestAxiosGet(requestOptions);
      const result = {
        status: response.status,
        responseTime: response.responseTime,
        startedAt: new Date(
          response.config.meta.requestStartedAt
        ).toISOString(),
        endedAt: new Date(response.requestEndedAt).toISOString(),
      };

      await this.onRequestSuccess(
        this.event.detail,
        result,
        iteration + 1 >= maxIterations
      );
    } catch (err) {
      console.log("Error: " + err);
      await this.onRequestFailure(
        this.event.detail,
        err,
        iteration + 1 >= maxIterations
      );
    }

    await this._sleep(wait);
    if (iteration + 1 < maxIterations) {
      await this._doAndWait(iteration + 1, requestOptions, maxIterations, wait);
    }
  }

  async handle() {
    try {
      await this.tasksApi.updateTask(
        this.event.detail.jobId,
        this.event.detail.taskId,
        "INPROGRESS"
      );
      if ("request" in this.event.detail) {
        const request = this.event.detail.request;
        const options = request.options;
        requests.makeRequest(
          options,
          async (status, data) =>
            await this.onRequestSuccess(request, status, data, true),
          async (error) => await this.onRequestFailure(request, error, true)
        );
      } else {
        const requestOptions = this.event.detail.requestOptions;
        const waitBetweenRequests = this.event.detail.wait * 1000;
        const repeatRequest = this.event.detail.repeats;
        await this._doAndWait(
          0,
          requestOptions,
          repeatRequest,
          waitBetweenRequests
        );
      }
    } catch (exc) {
      await this.terminateWithFailure(exc);
    }
  }
}

exports.Handler = Handler;
