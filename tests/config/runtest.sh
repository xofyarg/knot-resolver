#!/bin/bash -e
export SOURCE_PATH=$(cd "$(dirname "$0")" && pwd -P)
export TEST_FILE=${2}
export TMP_RUNDIR="$(mktemp -d)"
export KRESD_NO_LISTEN=1
function finish {
	rm -rf "${TMP_RUNDIR}"
}
trap finish EXIT

TEST_DIR="$(dirname $TEST_FILE)"

echo "config-test: ${2}"
cp -a "${TEST_DIR}/"* "${TMP_RUNDIR}/"
CMDLINE_ARGS=$(cat "${TEST_FILE%.test.lua}.args" 2>/dev/null || echo "")
EXPECTED_RETURNCODE=$(cat "${TEST_FILE%.test.lua}.returncode" 2>/dev/null || echo 0)
set +e
KRESD_NO_LISTEN=1 ${DEBUGGER} ${1} -f 1 -c ${SOURCE_PATH}/test.cfg $CMDLINE_ARGS "${TMP_RUNDIR}"
retcode=$?
if [ $retcode -ne $EXPECTED_RETURNCODE ]; then
	echo "Expected return code '$EXPECTED_RETURNCODE' got '$retcode'."
fi
test $retcode -eq $EXPECTED_RETURNCODE
