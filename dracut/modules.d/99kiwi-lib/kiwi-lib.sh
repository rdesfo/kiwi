#!/bin/bash
type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

function setup_debug {
    if getargbool 0 rd.kiwi.debug; then
        local log=/run/initramfs/log
        mkdir -p ${log}
        exec >> ${log}/boot.kiwi
        exec 2>> ${log}/boot.kiwi
        set -x
    fi
}

function lookup_disk_device_from_root {
    declare root=${root}
    local root_device=${root#block:}
    if [ -z "${root_device}" ];then
        die "No root device found"
    fi
    if [ -L "${root_device}" ];then
        root_device=/dev/$(basename "$(readlink "${root_device}")")
    fi
    echo /dev/"$(
        lsblk -n -r -s -o NAME,TYPE "${root_device}" |\
        grep disk | cut -f1 -d ' '
    )"
}

function import_file {
    # """
    # import file with key=value format. the function
    # will export each entry of the file as variable into
    # the current shell environment
    # """
    local source_format=/tmp/source_file_formatted
    # create clean input, no empty lines and comments
    grep -v '^$' "$1" | grep -v '^[ \t]*#' > ${source_format}
    # remove start/stop quoting from values
    sed -i -e s"#\(^[a-zA-Z0-9_]\+\)=[\"']\(.*\)[\"']#\1=\2#" ${source_format}
    # remove backslash quotes if any
    sed -i -e s"#\\\\\(.\)#\1#g" ${source_format}
    # quote simple quotation marks
    sed -i -e s"#'\+#'\\\\''#g" ${source_format}
    # add '...' quoting to values
    sed -i -e s"#\(^[a-zA-Z0-9_]\+\)=\(.*\)#\1='\2'#" ${source_format}
    source ${source_format} &>/dev/null
    while read -r line;do
        local key
        key=$(echo "${line}" | cut -d '=' -f1)
        eval "export ${key}" &>/dev/null
    done < ${source_format}
}
