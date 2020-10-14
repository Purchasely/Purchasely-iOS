#!/bin/bash

PROJECT_NAME="Purchasely"

function logError {
	echo -e "\033[31m${1}\033[0m"
}

function logSuccess {
	echo -e "\033[32m${1}\033[0m"
}

# Testing the script is executed in current directory
if [ $0 != "./deployPod.sh" ]; then
	logError "[ERROR] Must be executed from the directory where the script is located"
	exit 1
fi

# Test that nothing needs to be commited
git status | grep "nothing to commit"

if [ $? -ne 0 ]; then
	logError "[ERROR] You need to commit every changes before"
	exit 1
fi

# Increment version
CURRENT_VERSION=`cat ${PROJECT_NAME}.podspec | grep "s.version.*=.*" | sed "s/.*s.version.*=.*'\(.*\)'/\1/" 2> /dev/null`
BUILD_REVISION=`echo ${CURRENT_VERSION} | sed "s/.*\.\([0-9]*\)/\1/"`
NEW_BUILD_REVISION=$(($BUILD_REVISION+1))

if [ -z $1 ]; then
	NEW_VERSION=`echo ${CURRENT_VERSION} | sed "s/\([0-9.]*\.\)\([0-9]*\)/\1${NEW_BUILD_REVISION}/"`
	echo "No version set in parameters, bumping minor version to ${NEW_VERSION}"
else
	NEW_VERSION=$1
	echo "Using version set in parameters: ${NEW_VERSION}"
fi
cat ${PROJECT_NAME}.podspec | sed "s/${CURRENT_VERSION}/${NEW_VERSION}/" > ${PROJECT_NAME}-new.podspec

find Purchasely/Frameworks/Purchasely.xcframework -name Info.plist -exec plutil -replace CFBundleShortVersionString -string "${NEW_VERSION}" {} \;

#find Purchasely/Frameworks/Purchasely.framework -name Info.plist -exec plutil -replace CFBundleShortVersionString -string "${NEW_VERSION}" {} \;

#zip -r Purchasely/Frameworks/Purchasely.framework.zip Purchasely/Frameworks/Purchasely.framework
#mv Purchasely/Frameworks/Purchasely.framework.zip .

# Test that we only modified the version
NUMBER_CHANGES=`diff ${PROJECT_NAME}-new.podspec ${PROJECT_NAME}.podspec|wc -l|tr -d " "`
if [ ${NUMBER_CHANGES} -ne 4 ]; then
	logError "[ERROR] Podspec version bump modified more than one occurence, please check \n\
---------------------------------------------------------------------------- \n
	`diff ${PROJECT_NAME}-new.podspec ${PROJECT_NAME}.podspec`"
	exit 1
fi
mv ${PROJECT_NAME}-new.podspec ${PROJECT_NAME}.podspec

# Lint pod
pod lib lint ${PROJECT_NAME}.podspec --allow-warnings --sources=git@github.com:Purchasely/Purchasely-iOS.git,master --verbose

if [ $? -ne 0 ]; then
	logError "[ERROR] Problem when linting the pod"
	exit 1
fi

# Sending new podspec to git and adding tag
git add -A
git commit -m "Release ${NEW_VERSION}"
git tag ${NEW_VERSION}
git push --tags

# Push the podspec to the repo and update it
pod trunk push Purchasely.podspec

logSuccess "[SUCCESS] You're good to go !"
