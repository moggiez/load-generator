VERSION=$(shell cat version.txt)
version:
	./increment_version.sh
build:
	rm -rf ./dist/* & mkdir -p dist & zip ./dist/caller.lambda.$(VERSION).zip main.js &
deploy:
	aws s3 cp ./build/caller.lambda.zip s3://eventest-lambdas/$(VERSION)/
infra-debug:
	TF_LOG=DEBUG terraform apply -auto-approve
infra:
	TF_VAR_lambda_version=$(VERSION) terraform apply -auto-approve
plan-infra:
	TF_VAR_lambda_version=$(VERSION) terraform apply -auto-approve