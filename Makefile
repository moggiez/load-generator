VERSION=$(shell cat version.txt)
version:
	./increment_version.sh
build-cleanup:
	rm -rf ./dist/* & mkdir -p dist
build-worker:
	 zip ./dist/worker.lambda.$(VERSION).zip worker.js
build-driver:
	zip ./dist/driver.lambda.$(VERSION).zip driver.js
build: build-cleanup build-worker build-driver
deploy:
	aws s3 cp ./build/caller.lambda.zip s3://eventest-lambdas/$(VERSION)/
infra-debug:
	TF_LOG=DEBUG terraform apply -auto-approve
infra:
	TF_VAR_lambda_version=$(VERSION) terraform apply -auto-approve
plan-infra:
	TF_VAR_lambda_version=$(VERSION) terraform apply -auto-approve