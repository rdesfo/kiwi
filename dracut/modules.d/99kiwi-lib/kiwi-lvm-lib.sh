#!/bin/bash
type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

function activate_volume_group {
    declare kiwi_lvm=${kiwi_lvm}
    declare kiwi_lvmgroup=${kiwi_lvmgroup}
    if [ ! "${kiwi_lvm}" = "true" ];then
        return 1
    fi
    local vg_count=0
    local vg_name
    for vg_name in $(vgs --noheadings -o vg_name 2>/dev/null);do
        if [ "${vg_name}" = "${kiwi_lvmgroup}" ];then
            vg_count=$((vg_count + 1))
        fi
    done
    if [ ${vg_count} -gt 1 ];then
        die "Duplicate VolumeGroup name ${kiwi_lvmgroup} found !"
    fi
    vgchange -a y "${kiwi_lvmgroup}"
}
