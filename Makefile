VERSION=$(shell cat version.txt)
version:
	./increment_version.sh
build-cleanup:
	rm -rf ./dist/* & mkdir -p dist
build-worker:
	zip -r ./dist/worker.lambda.$(VERSION).zip worker/
build-driver:
	zip -r ./dist/driver.lambda.$(VERSION).zip driver/
build: build-cleanup build-worker build-driver
terraform-init:
	cd infrastructure && terraform init -force-copy -backend-config="bucket=moggiez-terraform-state-backend" -backend-config="key=terraform.state" -backend-config="region=eu-west-1"
infra-debug:
	cd infrastructure && TF_LOG=DEBUG terraform apply -auto-approve infra
infra:
	cd infrastructure && terraform init && TF_VAR_dist_version=$(VERSION) terraform apply -auto-approve
plan-infra:
	cd infrastructure && terraform init && TF_VAR_dist_version=$(VERSION) terraform apply -auto-approve
fmt-infra:
	cd infrastructure && terraform fmt
destroy-infra:
	cd infrastructure && terraform destroy
terraform-backend:
	cd infrastructure/terraform-backend && terraform init && terraform apply -auto-approve