#!/bin/bash
type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh
type lookup_disk_device_from_root >/dev/null 2>&1 || . /lib/kiwi-lib.sh
type create_parted_partitions >/dev/null 2>&1 || . /lib/kiwi-partitions-lib.sh
type activate_volume_group >/dev/null 2>&1 || . /lib/kiwi-lvm-lib.sh

#======================================
# functions
#--------------------------------------
function initialize {
    local profile=/.profile
    local partition_ids=/config.partids

    test -f ${profile} || \
        die "No profile setup found"
    test -f ${partition_ids} || \
        die "No partition id setup found"

    disk=$(lookup_disk_device_from_root)
    export disk

    import_file ${profile}
    import_file ${partition_ids}
}

function get_requested_swap_size {
    declare kiwi_oemswapMB=${kiwi_oemswapMB}
    declare kiwi_oemswap=${kiwi_oemswap}
    local swapsize
    if [ ! -z "${kiwi_oemswapMB}" ];then
        # swap size configured by kiwi description
        swapsize=${kiwi_oemswapMB}
    else
        # default swap size is twice times ramsize
        swapsize=$((
            $(grep MemTotal: /proc/meminfo | tr -dc '0-9') * 2 / 1024
        ))
    fi
    if [ ! "${kiwi_oemswap}" = "true" ];then
        # no swap wanted by kiwi description
        swapsize=0
    fi
    echo ${swapsize}
}

function repart_standard_disk {
    # """
    # repartition disk with read/write root filesystem
    # Image partition table layout is:
    # =====================================
    # pX:   [ boot ]
    # pX+1: ( root )  +luks
    # -------------------------------------
    declare root=${root}
    declare kiwi_oemrootMB=${kiwi_oemrootMB}
    declare kiwi_RootPart=${kiwi_RootPart}
    local disk_free_mbytes=$((
        $(get_free_disk_bytes "${disk}") / 1048576
    ))
    local disk_root_mbytes=$((
        $(get_partition_kbsize "${root#block:}") / 1024
    ))
    if [ -z "${kiwi_oemrootMB}" ];then
        local disk_have_root_system_mbytes=$((
            disk_root_mbytes + disk_free_mbytes - swapsize
        ))
        local min_additional_mbytes=${swapsize}
    else
        local disk_have_root_system_mbytes=${kiwi_oemrootMB}
        local min_additional_mbytes=$((
            swapsize + kiwi_oemrootMB - disk_root_mbytes
        ))
    fi
    if [ "${min_additional_mbytes}" -lt 5 ];then
        min_additional_mbytes=5
    fi
    local new_parts=0
    if [ "${kiwi_oemswap}" = "true" ];then
        new_parts=$((new_parts + 1))
    fi
    # check if we can repart this disk
    if ! check_repart_possible \
        ${disk_root_mbytes} ${disk_free_mbytes} ${min_additional_mbytes}
    then
        return
    fi
    # repart root partition
    local root_part_size=+${disk_have_root_system_mbytes}M
    if [ -z "${kiwi_oemrootMB}" ] && [ ${new_parts} -eq 0 ];then
        # no new parts and no rootsize limit, use rest disk space
        root_part_size=.
    fi
    create_parted_partitions \
        d "${kiwi_RootPart}" \
        n p:lxroot "${kiwi_RootPart}" . "${root_part_size}"
    # add swap partition
    if [ "${kiwi_oemswap}" = "true" ];then
        export kiwi_SwapPart=$((kiwi_RootPart + 1))
        local swap_part_size=+${swapsize}M
        if [ -z "${kiwi_oemrootMB}" ] && [ ${new_parts} -eq 1 ];then
            # exactly one new part and no rootsize limit, use rest disk space
            swap_part_size=.
        fi
        create_parted_partitions \
            n p:lxswap ${kiwi_SwapPart} . ${swap_part_size} \
            t ${kiwi_SwapPart} 82
    fi
}

function repart_lvm_disk {
    # TODO
    return
}

function check_repart_possible {
    declare kiwi_oemrootMB=${kiwi_oemrootMB}
    local disk_root_mbytes=$1
    local disk_free_mbytes=$2
    local min_additional_mbytes=$3
    if [ ! -z "${kiwi_oemrootMB}" ];then
        if [ "${kiwi_oemrootMB}" -lt "${disk_root_mbytes}" ];then
            # specified oem-systemsize is smaller than root partition
            warn "Requested OEM systemsize is smaller than root partition"
            warn "Disk won't be re-partitioned !"
            echo
            warn "Current Root partition: ${disk_root_mbytes} MB"
            warn "==> Requested size: ${kiwi_oemrootMB} MB"
            return 1
        fi
    fi
    if [ "${min_additional_mbytes}" -gt "${disk_free_mbytes}" ];then
        # Requested sizes for root and swap exceeds free space on disk
        warn "Requested sizes exceeds free space on the disk:"
        warn "Disk won't be re-partitioned !"
        echo
        warn "Minimum required additional size: ${min_additional_mbytes} MB:"
        if [ ! -z "${kiwi_oemrootMB}" ];then
            local share=$((kiwi_oemrootMB - disk_root_mbytes))
            warn "==> Root's share is: ${share} MB"
        fi
        if [ ${swapsize} -gt 0 ];then
            warn "==> Swap's share is: ${swapsize} MB"
        fi
        warn "Free Space on disk: ${disk_free_mbytes} MB"
        return 1
    fi
    return 0
}

#======================================
# perform repart/resize operations
#--------------------------------------
PATH=/usr/sbin:/usr/bin:/sbin:/bin

setup_debug

# initialize for disk repartition
initialize

# repartition disk
if [ "$(get_partition_table_type "${disk}")" = 'gpt' ];then
    relocate_gpt_at_end_of_disk "${disk}"
fi
if activate_volume_group; then
    repart_lvm_disk
else
    repart_standard_disk
fi

# TODO:
# code of: finalizePartitionTable

# setup luks maps
# TODO

# activate swap space
# TODO
