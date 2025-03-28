#!/bin/sh
#
# Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
#
# You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
# copy, modify, and distribute this software in source code or binary form for use
# in connection with the web services and APIs provided by Facebook.
#
# As with any software that integrates with the Facebook platform, your use of
# this software is subject to the Facebook Developer Principles and Policies
# [http://developers.facebook.com/policy/]. This copyright notice shall be
# included in all copies or substantial portions of the software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN

. $(dirname $0)/common.sh

PROPS_PATH="$PROJECT_ROOT/scripts/build.properties"
source $PROPS_PATH

info "Starting build"
# Check for required settings
if [ -z "$ANDROID_HOME" ]; then
    echo "${RED}ERROR: ANDROID_HOME environment variable not set${NC}"
    echo "${RED}Please set the ANDROID_HOME environment variable to point to your android sdk${NC}"
    exit 1
fi

localBuild=false
if [[ $* == *--local* ]]; then
  localBuild=true
fi

# Copy the required libs
UNITY_PLUGIN_FACEBOOK="$UNITY_PACKAGE_ROOT/Assets/FacebookSDK/Plugins/Android/libs/"

FB_WRAPPER_PATH=$PROJECT_ROOT/facebook-android-wrapper
FB_WRAPPER_LIB_PATH=$FB_WRAPPER_PATH/libs
FB_ANDROID_SDK_WRAPPER_NAME="facebook-android-wrapper-release.aar"
FB_ANDROID_SDK_WRAPPER="$FB_WRAPPER_PATH/build/outputs/aar/$FB_ANDROID_SDK_WRAPPER_NAME"

FB_SDK_AAR_NAME="$FB_ANDROID_SDK_ARTIFACT_ID-$FB_ANDROID_SDK_VERSION.$FB_ANDROID_SDK_PACKAGING"
FB_SDK_AAR_PATH="$FB_WRAPPER_LIB_PATH/$FB_SDK_AAR_NAME"
FB_SDK_AAR_PATH_FOLDER="$FB_WRAPPER_LIB_PATH/"

BOLTS_SDK_JAR_NAME="$BOLTS_ARTIFACT_ID-$BOLTS_VERSION.jar"
BOLTS_JAR_PATH="$FB_WRAPPER_LIB_PATH/$BOLTS_SDK_JAR_NAME"
BOLTS_TASKS_SDK_JAR_NAME="$BOLTS_TASKS_ARTIFACT_ID-$BOLTS_VERSION.jar"
BOLTS_TASKS_JAR_PATH="$FB_WRAPPER_LIB_PATH/$BOLTS_TASKS_SDK_JAR_NAME"
BOLTS_APPLINKS_SDK_JAR_NAME="$BOLTS_APPLINKS_ARTIFACT_ID-$BOLTS_VERSION.jar"
BOLTS_APPLINKS_JAR_PATH="$FB_WRAPPER_LIB_PATH/$BOLTS_APPLINKS_SDK_JAR_NAME"

# Local build only properties
FB_ANDROID_SDK_AAR="facebook/build/outputs/aar/facebook-release.aar"

# Get Unity Jar Resolver
info "Step 1 - Download $UNITY_JAR_RESOLVER_NAME"
downloadUnityJarResolverFromGithub

info "Step 2 - Build android wrapper"
pushd $FB_WRAPPER_PATH
if [ "$localBuild" = true ]; then
  ./gradlew clean -PlocalRepo=libs -PsdkVersion=$FB_ANDROID_SDK_VERSION || die "Failed to perform gradle clean"
  ./gradlew assemble -PlocalRepo=libs -PsdkVersion=$FB_ANDROID_SDK_VERSION || die "Failed to build facebook android wrapper"
else
  ./gradlew clean -PsdkVersion=$FB_ANDROID_SDK_VERSION || die "Failed to perform gradle clean"
  ./gradlew assemble -PsdkVersion=$FB_ANDROID_SDK_VERSION || die "Failed to build facebook android wrapper"
fi
popd

info "Step 4 - Copy libs to unity plugin folder"
if [ ! -d "$UNITY_PLUGIN_FACEBOOK" ]; then
  mkdir -p $UNITY_PLUGIN_FACEBOOK || die "Failed to make unity plugin lib folder"
fi
# clean the unity lib folder
rm -r -f $UNITY_PLUGIN_FACEBOOK/*.jar
rm -r -f $UNITY_PLUGIN_FACEBOOK/*.aar
# Copy aars
cp $FB_ANDROID_SDK_WRAPPER  $UNITY_PLUGIN_FACEBOOK || die 'Failed to copy wrapper to unity plugin folder'
# Rename wrapper to include sdk version
mv $UNITY_PLUGIN_FACEBOOK/$FB_ANDROID_SDK_WRAPPER_NAME "$UNITY_PLUGIN_FACEBOOK/facebook-android-wrapper-$SDK_VERSION.aar"

info "Done!"
