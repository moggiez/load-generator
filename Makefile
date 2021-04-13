VERSION=$(shell cat version.txt)
version-build:
	./increment_version.sh
build-cleanup:
	rm -rf ./dist/* & mkdir -p dist
build-worker:
	cd code/worker/ && zip -r ../../dist/worker_lambda.$(VERSION).zip ./
build-driver:
	cd code/driver/ && zip -r ../../dist/driver_lambda.$(VERSION).zip ./
build-archiver:
	cd code/archiver/ && zip -r ../../dist/archiver_lambda.$(VERSION).zip ./
build-playbook-api:
	cd code/api/customer/playbook/ && zip -r ../../../../dist/playbook_api.$(VERSION).zip ./
build: build-cleanup build-worker build-driver build-archiver build-playbook-api
infra-init:
	cd infrastructure && terraform init -force-copy -backend-config="bucket=moggiez-terraform-state-backend" -backend-config="key=terraform.state" -backend-config="region=eu-west-1"
infra-debug:
	cd infrastructure && TF_LOG=DEBUG terraform apply -auto-approve infra
deploy: build
	cd infrastructure && terraform init && TF_VAR_dist_version=$(VERSION) terraform apply -auto-approve
preview: build
	cd infrastructure && terraform init && TF_VAR_dist_version=$(VERSION) terraform plan
fmt:
	cd infrastructure && terraform fmt
undeploy:
	cd infrastructure && terraform destroy