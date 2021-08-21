#! /bin/bash

CODE_DIR=$PWD/code
DIST_DIR=$PWD/dist
LAMBDAS=("domain_validator")
 
for lambda in "${LAMBDAS[@]}"
do
    echo "Building lambda '$lambda'..."
	$PWD/scripts/build_and_package_lambda.sh $CODE_DIR/$lambda $DIST_DIR ${lambda}_lambda.zip
    echo ""
done
