#! /bin/bash

CODE_DIR=$PWD/code
LIBS_DIR=$PWD/code/libs
DIST_DIR=$PWD/dist
LAMBDAS=("driver" "worker" "archiver")
 
for lambda in "${LAMBDAS[@]}"
do
    echo "Building lambda '$lambda'..."
	$PWD/scripts/build_and_package_lambda.sh $CODE_DIR/$lambda $DIST_DIR ${lambda}_lambda.zip
    echo ""
done
