#!/bin/bash
type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

. /lib/kiwi-dialog-lib.sh
. /lib/kiwi-filesystem-lib.sh
. /lib/kiwi-luks-lib.sh
. /lib/kiwi-lvm-lib.sh
. /lib/kiwi-mdraid-lib.sh
. /lib/kiwi-partitions-lib.sh

function setupDebugMode {
    if getargbool 0 rd.kiwi.debug; then
        local log=/run/initramfs/log
        mkdir -p ${log}
        exec >> ${log}/boot.kiwi
        exec 2>> ${log}/boot.kiwi
        set -x
    fi
}
