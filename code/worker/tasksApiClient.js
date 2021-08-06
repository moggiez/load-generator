"use strict";

const { HttpClient } = require("./httpClient");

const usersApiUrl = "https://users-api.moggies.io";
const jobsApiUrl = "https://jobs-api.moggies.io";

class TasksApiClient {
  constructor(user) {
    this.http = new HttpClient(user);
    this.user = user;
    this.organisationId = null;
  }

  async _getOrganisationId() {
    if (this.organisationId != null) {
      return this.organisationId;
    }

    const usersResponse = await this.http.get(`${usersApiUrl}/${this.user.id}`);
    if (
      usersResponse.status != 200 ||
      !("OrganisationId" in usersResponse.data)
    ) {
      throw new Error("User organisation could not be retrieved.");
    }
    return usersResponse.data.OrganisationId;
  }

  async updateTask(jobId, taskId, newState, result, error) {
    const orgId = await this._getOrganisationId();
    const taskUrl = `${jobsApiUrl}/${orgId}/jobs/${jobId}/tasks/${taskId}`;

    const jobResponse = await this.http.get(taskUrl);
    const jobData = jobResponse.data.data;
    const job = jobData.length > 0 ? jobData[0] : null;

    if (job != null && "JobId" in job && "TaskId" in job) {
      const updatedRecord = { ...job.data };
      delete updatedRecord.JobId;
      delete updatedRecord.TaskId;
      updatedRecord["TaskState"] = newState;
      if (result) {
        updatedRecord["TaskResult"] = result;
      }
      if (error) {
        updatedRecord["TaskError"] = error;
      }
      return await this.http.put(taskUrl, updatedRecord);
    } else {
      throw new Error(
        `Task with id ${taskId} for job with id ${jobId} could not be retrieved.`
      );
    }
  }
}

exports.TasksApiClient = TasksApiClient;
