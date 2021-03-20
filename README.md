# Development
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
cd infrastructure
terraform init
```

## Packaging the code of the lambda functions
Run the code below in the terminal:
```bash
make version
make build
```
It will output the zipped code in the `dist` folder.

## IaC and deployment
* Run ```make plan-infra``` to preview the deployment.
* Run ```make infra``` to do the actual deployment