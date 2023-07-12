#!/bin/bash
export LC_ALL=C
unset CDPATH

SELF=$(basename "${BASH_SOURCE[0]}")
msg() { echo "${SELF}: $*" >&2; }
die() { msg "$*"; exit 1; }
try() { ( "$@" ) || die "failed: $*"; }


msg "Determining container command"
if [ -z "${CONTAINER_CMD}" ]; then
	CONTAINER_CMD=$(command -v docker || echo )
fi
if [ -z "${CONTAINER_CMD}" ]; then
	CONTAINER_CMD=$(command -v podman || echo )
fi
if [ -z "${CONTAINER_CMD}" ]; then
	die "Failed to determine container command"
fi
msg "Container command: '${CONTAINER_CMD}'"


msg "Creating temporary directory"
TMPDIR="$(mktemp -d)"
try stat "${TMPDIR}" > /dev/null
on_exit() { [[ -d "${TMPDIR}" ]] && rm -rf "${TMPDIR}"; }
trap on_exit EXIT
msg "Temporary directory: '${TMPDIR}'"


msg "Starting samba container"
CONTAINER_ID="$(${CONTAINER_CMD} run --network=none --name samba \
	--volume="${TMPDIR}":/share:Z --rm  -d "${LOCAL_TAG}")"
sleep 1 # give samba a second to come up
try "${CONTAINER_CMD}" container exists "${CONTAINER_ID}"
msg "Container started: '${CONTAINER_ID}'"


msg "Listing samba shares"
try "${CONTAINER_CMD}" exec "${CONTAINER_ID}" smbclient -U% -L 127.0.0.1


msg "Stopping samba container"
try "${CONTAINER_CMD}" kill "${CONTAINER_ID}"
msg "Samba container stopped"

