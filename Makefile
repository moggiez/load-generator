VERSION=$(shell cat version.txt)
build:
	rm ./dist/caller.lambda.zip & mkdir -p dist & zip ./dist/caller.lambda.zip main.js
deploy:
	aws s3 cp ./build/caller.lambda.zip s3://eventest-lambdas/$(VERSION)/
infra-debug:
	TF_LOG=DEBUG terraform apply -auto-approve
infra:
	terraform apply -auto-approve