#!/bin/bash
type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

function resizeFilesystem {
    local device=$1
    local resize_fs
    local check
    local mpoint=/fs-resize
    local fstype=$(probeFileSystem ${device})
    case ${fstype} in
    ext2|ext3|ext4)
        resize_fs="resize2fs -f -p ${device}"
    ;;
    btrfs)
        resize_fs="mkdir -p ${mpoint} && mount ${device} ${mpoint} &&"
        resize_fs="${resize_fs} btrfs filesystem resize max ${mpoint}"
        resize_fs="${resize_fs};umount ${mpoint} && rmdir ${mpoint}"
    ;;
    xfs)
        resize_fs="mkdir -p ${mpoint} && mount ${device} ${mpoint} &&"
        resize_fs="${resize_fs} xfs_growfs ${mpoint}"
        resize_fs="${resize_fs};umount ${mpoint} && rmdir ${mpoint}"
    ;;
    *)
        # don't know how to resize this filesystem
        warn "Don't know how to resize ${fstype}... skipped"
        return
    ;;
    esac
    if _is_ramdisk_device ${device}; then
        checkFilesystem ${device}
    fi
    info "Resizing ${fstype} filesystem on ${device}..."
    if ! eval ${resize_fs}; then
        die "Failed to resize filesystem"
    fi
}

function checkFilesystem {
    local device=$1
    local check_fs
    local fstype=$(probeFileSystem ${device})
    case ${fstype} in
    ext2|ext3|ext4)
        check_fs="e2fsck -p -f ${device}"
    ;;
    btrfs)
        check_fs="btrfsck ${device}"
    ;;
    xfs)
        check_fs="xfs_repair -n ${device}"
    ;;
    *)
        # don't know how to check this filesystem
        warn "Don't know how to check ${fstype}... skipped"
        return
    ;;
    esac
    info "Checking ${fstype} filesystem on ${device}..."
    if ! eval ${check_fs}; then
        die "Failed to check filesystem"
    fi
}

function probeFileSystem {
    local device=$1
    local fstype=$(blkid ${device} -s TYPE -o value)
    if [ -z "${fstype}" ];then
        fstype=unknown
    fi
    if [ "${fstype}" = "crypto_LUKS" ];then
        fstype=luks
    fi
    echo ${fstype}
}

#======================================
# Methods considered private
#--------------------------------------
function _is_ramdisk_device {
    local device=$1
    if echo $device | grep -qi "/dev/ram";then
        return 1
    fi
    return 0
}
