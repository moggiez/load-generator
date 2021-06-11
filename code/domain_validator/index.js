"use strict";
const dns = require("dns");
const db = require("db");

const domains = new db.Table(db.tableConfigs.domains);

const DOMAIN_STATES = {
  PENDING_VALIDATION: "PENDING_VALIDATION",
  VALIDATED: "VALID",
  INVALID: "INVALID",
};

const cnameFixed = "htqonfzjrsqxzgwrrjttrygqypgm4fnw._domainkey.moggies.io";
const expectedValue = "htqonfzjrsqxzgwrrjttrygqypgm4fnw.dkim.amazonses.com";

const setDomainState = async (domain, state) => {
  const updated = { ...domain };
  delete updated.OrganisationId;
  delete updated.DomainName;
  updated["State"] = state;

  return await domain.update(domain.OrganisationId, domain.DomainName, updated);
};

const resolve = async (cname) => {
  return new Promise((resolve, reject) => {
    dns.resolveCname(cname, (err, addresses) => {
      if (err) {
        reject(err);
      } else {
        resolve(addresses.length > 0 ? addresses[0] : null);
      }
    });
  });
};

exports.handler = async function (event, context, callback) {
  try {
    const cnameValue = await resolve(cnameFixed);
    let newState = DOMAIN_STATES.PENDING_VALIDATION;
    if (cnameValue != null) {
      newState =
        cnameValue == expectedValue
          ? DOMAIN_STATES.VALIDATED
          : DOMAIN_STATES.INVALID;
    }
    console.log("cnameValue", newState);
    callback(null, "Success");
  } catch (err) {
    console.log(err);
    callback(err, null);
  }
};
