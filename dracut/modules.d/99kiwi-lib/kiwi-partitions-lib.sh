#!/bin/bash
type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

#======================================
# Global exports
#--------------------------------------
export partedTableType
export partedOutput
export partedCylCount
export partedCylKSize
export partedStartSectors
export partedEndSectors

#======================================
# Library Methods
#--------------------------------------
function createPartedPartitions {
    # """
    # create partitions using parted
    # """
    local disk_device=$1
    local partition_setup=$2
    local index=0
    local commands
    local partid
    local part_name
    local part_start_cyl
    local part_stop_cyl
    local part_type
    local cmd_list
    local cmd

    _partedInit ${disk_device}
    _partedSectorInit ${disk_device}

    # put partition setup in a command list(cmd_list)
    for cmd in ${partition_setup};do
        cmd_list[$index]=${cmd}
        index=$((index + 1))
    done

    # operate on index based cmd_list
    index=0
    for cmd in ${cmd_list[*]};do
        case ${cmd} in
        "d")
            # delete a partition...
            partid=${cmd_list[$index + 1]}
            partid=$((partid / 1))
            commands="${commands} rm $partid"
            _partedWrite "${disk_device}" "${commands}"
            unset commands
        ;;
        "n")
            # create a partition...
            part_name=${cmd_list[$index + 1]}
            partid=${cmd_list[$index + 2]}
            partid=$((partid / 1))
            part_start_cyl=${cmd_list[$index + 3]}
            if [ ! "${partedTableType}" = "gpt" ];then
                part_name=primary
            else
                part_name=$(echo ${part_name} | cut -f2 -d:)
            fi
            if [ "${part_start_cyl}" = "1" ];then
                part_start_cyl=$(echo ${partedStartSectors} |\
                    cut -f ${partid} -d:
                )
            fi
            if [ ${part_start_cyl} = "." ];then
                # start is next cylinder according to previous partition
                part_start_cyl=$((partid - 1))
                if [ ${part_start_cyl} -gt 0 ];then
                    part_start_cyl=$(echo ${partedEndSectors} |\
                        cut -f ${part_start_cyl} -d:
                    )
                else
                    part_start_cyl=$(echo ${partedStartSectors} |\
                        cut -f ${partid} -d:
                    )
                fi
            fi
            part_stop_cyl=${cmd_list[$index + 4]}
            if [ ${part_stop_cyl} = "." ];then
                # use rest of the disk for partition end
                part_stop_cyl=${partedCylCount}
            elif echo ${part_stop_cyl} | grep -qi M;then
                # calculate stopp cylinder from size
                part_stop_cyl=$((partid - 1))
                if [ ${part_stop_cyl} -gt 0 ];then
                    part_stop_cyl=$(_partedEndCylinder ${part_stop_cyl})
                fi
                local part_size_mbytes=$(
                    echo ${cmd_list[$index + 4]} | cut -f1 -dM | tr -d +
                )
                local part_size_cyl=$(
                    _partedMBToCylinder ${part_size_mbytes}
                )
                part_stop_cyl=$((1 + part_stop_cyl + part_size_cyl))
                if [ ${part_stop_cyl} -gt ${partedCylCount} ];then
                    # given size is out of bounds, reduce to end of disk
                    part_stop_cyl=${partedCylCount}
                fi
            fi
            commands="${commands} mkpart ${part_name}"
            commands="${commands} ${part_start_cyl} ${part_stop_cyl}"
            _partedWrite "${disk_device}" "${commands}"
            _partedSectorInit ${disk_device}
            unset commands
        ;;
        "t")
            # change a partition type...
            part_type=${cmd_list[$index + 2]}
            partid=${cmd_list[$index + 1]}
            local flagok=1
            if [ "${part_type}" = "82" ];then
                # parted can not consistently set swap flag.
                # There is no general solution to this issue.
                # Thus swap flag setup is skipped
                flagok=0
            elif [ "${part_type}" = "fd" ];then
                commands="${commands} set ${partid} raid on"
            elif [ "${part_type}" = "8e" ];then
                commands="${commands} set ${partid} lvm on"
            elif [ "${part_type}" = "83" ];then
                # default partition type set by parted is linux(83)
                flagok=0
            fi
            if [ ! "${partedTableType}" = "gpt" ] && [ ${flagok} = 1 ];then
                _partedWrite "${disk_device}" "${commands}"
            fi
            unset commands
        ;;
        esac
        index=$((index + 1))
    done
    partprobe ${disk_device}
}

function createFdasdPartitions {
    # """
    # create partitions using fdasd (s390)
    # """
    local disk_device=$1
    local partition_setup=$2
    local partition_setup_file=/run/fdasd.cmds
    local ignore_cmd=0
    local ignore_cmd_once=0
    local cmd
    for cmd in ${partition_setup};do
        if [ ${ignore_cmd} = 1 ] && echo ${cmd} | grep -qE '[dntwq]';then
            ignore_cmd=0
        elif [ ${ignore_cmd} = 1 ];then
            continue
        fi
        if [ ${ignore_cmd_once} = "1" ];then
            ignore_cmd_once=0
            continue
        fi
        if [ ${cmd} = "a" ];then
            ignore_cmd=1
            continue
        fi
        if [[ ${cmd} =~ ^p: ]];then
            ignore_cmd_once=1
            continue
        fi
        if [ ${cmd} = "83" ] || [ ${cmd} = "8e" ];then
            cmd=1
        fi
        if [ ${cmd} = "82" ];then
            cmd=2
        fi
        if [ ${cmd} = "." ];then
            echo >> ${partition_setup_file}
            continue
        fi
        echo $cmd >> ${partition_setup_file}
    done
    echo "w" >> ${partition_setup_file}
    echo "q" >> ${partition_setup_file}
    if ! fdasd ${disk_device} < ${partition_setup_file} 1>&2;then
        die "Failed to create partition table"
    fi
    partprobe ${disk_device}
}


#======================================
# Methods considered private
#--------------------------------------
function _partedInit {
    # """
    # initialize current partition table output
    # as well as the number of cylinders and the
    # cyliner size in kB for this disk
    # """
    local disk_device=$1
    local IFS=""
    local parted=$(
        parted -m -s ${disk_device} unit cyl print | grep -v Warning:
    )
    local header=$(echo ${parted} | head -n 3 | tail -n 1)
    local ccount=$(
        echo ${parted} | grep ^${disk_device} | cut -f 2 -d: | tr -d cyl
    )
    local cksize=$(echo ${header} | cut -f4 -d: | cut -f1 -dk)
    local diskhd=$(echo ${parted} | head -n 3 | tail -n 2 | head -n 1)
    local plabel=$(echo ${diskhd} | cut -f6 -d:)
    if [[ ${plabel} =~ gpt ]];then
        plabel=gpt
    fi
    export partedTableType=${plabel}
    export partedOutput=${parted}
    export partedCylCount=${ccount}
    export partedCylKSize=${cksize}
}

function _partedSectorInit {
    # """
    # calculate aligned start/end sectors of
    # the current table.
    #
    # Uses following kiwi profile values if present:
    #
    # kiwi_align
    # kiwi_sectorsize
    # kiwi_startsector
    #
    # """
    local disk_device=$1
    local s_start
    local s_stopp
    local align=1048576
    local sector_size=512
    local sector_start=2048
    [ ! -z "${kiwi_align}" ] && align=${kiwi_align}
    [ ! -z "${kiwi_sectorsize}" ] && sector_size=${kiwi_sectorsize}
    [ ! -z "${kiwi_startsector}" ] && sector_start=${kiwi_startsector}
    local align=$((align / sector_size))

    unset partedStartSectors
    unset partedEndSectors

    for i in $(
        parted -m -s ${disk_device} unit s print |\
        grep -E ^[1-9]+:| cut -f2-3 -d: | tr -d s
    );do
        s_start=$(echo $i | cut -f1 -d:)
        s_stopp=$(echo $i | cut -f2 -d:)
        if [ -z "${partedStartSectors}" ];then
            partedStartSectors=${s_start}s
        else
            partedStartSectors=${partedStartSectors}:${s_start}s
        fi
        if [ -z "${partedEndSectors}" ];then
            partedEndSectors=$((s_stopp/align*align+align))s
        else
            partedEndSectors=${partedEndSectors}:$((s_stopp/align*align+align))s
        fi
    done
    # The default start sector applies for an empty disk
    if [ -z "${partedStartSectors}" ];then
        partedStartSectors=${sector_start}s
    fi
}

function _partedEndCylinder {
    # """
    # return end cylinder of given partition, next
    # partition must start at return value plus 1
    # """
    local partition_id=$(($1 + 3))
    local IFS=""
    local header=$(echo ${partedOutput} | head -n ${partition_id} | tail -n 1)
    local ccount=$(echo ${header} | cut -f3 -d: | tr -d cyl)
    echo ${ccount}
}

function _partedMBToCylinder {
    # """
    # convert partition size in MB to cylinder count
    # """
    local sizeBytes=$(($1 * 1048576))
    # bc truncates to zero decimal places, which results in
    # a partition that is slightly smaller than the requested
    # size. Add one cylinder to compensate.
    local required_cylinders=$(
        echo "scale=0; ${sizeBytes} / (${partedCylKSize} * 1000) + 1" | bc
    )
    echo ${required_cylinders}
}

function _partedWrite {
    # """
    # call parted with current command queue.
    # and reinitialize the new table data
    # """
    local disk_device=$1
    local commands=$2
    if ! parted -a cyl -m -s ${disk_device} unit cyl ${commands};then
        die "Failed to create partition table"
    fi
    _partedInit ${disk_device}
}
