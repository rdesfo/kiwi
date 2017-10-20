#!/bin/bash
type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
type createPartedPartitions >/dev/null 2>&1 || . /lib/kiwi-lib.sh

setupDebugMode

echo "DEBUGGING" 1>&2
echo $root 1>&2

# TODO
