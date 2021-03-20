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
deploy:
	aws s3 cp ./build/caller.lambda.zip s3://eventest-lambdas/$(VERSION)/
infra-debug:
	cd infrastructure && TF_LOG=DEBUG terraform apply -auto-approve infra
infra:
	cd infrastructure && TF_VAR_lambda_version=$(VERSION) terraform apply -auto-approve
plan-infra:
	cd infrastructure && TF_VAR_lambda_version=$(VERSION) terraform apply -auto-approve 