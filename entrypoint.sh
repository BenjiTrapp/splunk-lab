#!/bin/bash
#
# Script to run from Splunk
#


SPLUNK_PASSWORD="${SPLUNK_PASSWORD:=password}"


#
# Require the user to accept the license to continue
#
if test "$SPLUNK_START_ARGS" != "--accept-license"
then
	echo "! "
	echo "! You need to accept the Splunk License in order to continue."
	echo "! Please restart this container with SPLUNK_START_ARGS set to \"--accept-license\" "
	echo "! as follows: "
	echo "! "
	echo "! SPLUNK_START_ARGS=--accept-license"
	echo "! "
	exit 1
fi

#
# Check for bad passwords.
#
if test "$SPLUNK_PASSWORD" == "password"
then
	echo "! "
	echo "! "
	echo "! Cowardly refusing to set the password to 'password'. Please set a different password."
	echo "! "
	echo "! If you need help picking a secure password, there's an app for that:"
	echo "! "
	echo "!	https://diceware.dmuth.org/"
	echo "! "
	echo "! "
	exit 1

elif test "$SPLUNK_PASSWORD" == "12345"
then
	echo "! "
	echo "! "
	echo "! This is not Planet Spaceball.  Please don't use 12345 as a password."
	echo "! "
	echo "! "
	exit 1

fi


PASSWORD_LEN=${#SPLUNK_PASSWORD}
if test $PASSWORD_LEN -lt 8
then
	echo "! "
	echo "! "
	echo "! Admin password needs to be at least 8 characters!"
	echo "! "
	echo "! Password specified: ${SPLUNK_PASSWORD}"
	echo "! "
	echo "! "
	exit 1
fi


#
# Set our default password
#
pushd /opt/splunk/etc/system/local/ >/dev/null

cat user-seed.conf.in | sed -e "s/%password%/${SPLUNK_PASSWORD}/" > user-seed.conf
cat web.conf.in | sed -e "s/%password%/${SPLUNK_PASSWORD}/" > web.conf


#
# If a Rest Modular API key was specified, add it in.
#
if test "$REST_KEY"
then
	SRC="activation_key = Visit https://www.baboonbones.com/#activation"
	REPLACE="activation_key = ${REST_KEY}"

	sed -i "s|${SRC}|${REPLACE}|" ${FILE} /opt/splunk/etc/system/local/inputs.conf

fi

popd > /dev/null

#
# Start Splunk
#
/opt/splunk/bin/splunk start --accept-license

echo "# "
echo "# "
echo "# Here are some ways in which to run this container: "
echo "# "
echo "# Persist data between runs:"
echo "# 	docker run -p 8000:8000 -v \$(pwd)/data:/data dmuth1/splunk-lab "
echo "# "
echo "# Persist data, mount current directory as /mnt, and spawn an interactive shell: "
echo "# 	docker run -p 8000:8000 -v \$(pwd)/data:/data -v \$(pwd):/mnt -it dmuth1/splunk-lab bash "
echo "# "
echo "# Persist data and ingest multiple directories:"
echo "#     docker run -p 8000:8000 -v $(pwd)/data:/data -v /var/log:/logs/syslog -v /opt/log:/logs/opt/ dmuth1/splunk-lab"
echo "# "
echo "# "


if test "$1"
then
	echo "# "
	echo "# Arguments detected! "
	echo "# "
	echo "# Executing: $@"
	echo "# "

	exec "$@"

fi


#
# Tail this file so that Splunk keeps running
#
tail -f /opt/splunk/var/log/splunk/splunkd_stderr.log



