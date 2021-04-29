const eventBusName = "moggiez-load-test";

const sendEvent = (eventbridge, eventParams, onSuccess, onFailure) => {
  eventbridge.putEvents(eventParams, (err, data) => {
    if (err) {
      onFailure(err);
    } else {
      onSuccess(data.ruleArn);
    }
  });
};

const buildEventParams = (source, type, payload) => {
  return {
    Entries: [
      {
        Source: source,
        DetailType: type,
        Detail: JSON.stringify(payload),
        EventBusName: eventBusName,
      },
    ],
  };
};

exports.buildEventParams = buildEventParams;
exports.sendEvent = sendEvent;
