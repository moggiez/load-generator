# Load Generator

API and event driven components (lambdas) to orchestrate the generation of load on customer APIs.

- Domain Validator - validates domains attached to an organisation, validation is done via DNS

Scheduled lambdas:
`Domain Validator` lambda is triggered on a schedule to perform their work. The schedule is configured via IaC.

# Development

TL;DR;

- Scrips are used to package lambdas
- Makefile used to perform previews, actual deployments, linting of the code and other common operations

## Setting up the development environment

### Install Terraform v0.14.8 or above

#### Mac OS X

Run in terminal:

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
terraform -install-autocomplete
```

### Initialize terraform

Run in terminal:

```bash
make infra-init
```

### Create terraform backend in AWS (if not already created)

Run in terminal:

```bash
make terraform-backend
```

## IaC and deployment

### Deployment from your local machine

- Run `make preview` to preview the deployment.
- Run `make deploy` to do the actual deployment

### Automatic deployment

The application is deployed automatically with GitHub action when a push to `master` branch is made.

## Updating the version of the code

- Update the base version (it uses SemVer)
- To update the build number

```bash
make version-build
```

## Only buildiong the packages of the lambda functions

Run the code below in the terminal:

```bash
make build
```

It will output the zipped code in the `dist` folder.
