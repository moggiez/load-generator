VERSION=$(shell cat version.txt)

version-build:
	./increment_version.sh

build-cleanup:
	rm -rf ./dist/* & mkdir -p dist

build-worker:
	cd code/worker/ && npm i && zip -r ../../dist/worker_lambda.$(VERSION).zip ./

build-driver:
	cd code/driver/ && npm i && zip -r ../../dist/driver_lambda.$(VERSION).zip ./

build-archiver:
	cd code/archiver/ && npm i && zip -r ../../dist/archiver_lambda.$(VERSION).zip ./

build: build-cleanup build-worker build-driver build-archiver

infra-init:
	cd infrastructure && terraform init -force-copy -backend-config="bucket=moggies.io-terraform-state-backend" -backend-config="dynamodb_table=moggies.io-load-generator-terraform_state" -backend-config="key=load-generator-terraform.state" -backend-config="region=eu-west-1"

infra-debug:
	cd infrastructure && TF_LOG=DEBUG terraform apply -auto-approve infra

deploy: build
	cd infrastructure && terraform init && TF_VAR_dist_version=$(VERSION) terraform apply -auto-approve

preview: build
	cd infrastructure && terraform init && TF_VAR_dist_version=$(VERSION) terraform plan

fmt:
	cd infrastructure && terraform fmt -recursive

undeploy:
	cd infrastructure && terraform destroy