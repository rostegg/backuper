#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

curr_dir=$(pwd)
backup_dir="${curr_dir}/.backuper"

usage="$(basename "$0") [info|backup|restore|clear]
    info <file_name>                    show backup status about file 
    backup <file_name>                  backup file or directory
    restore <file_name> <restore_id>    restore file from backup, restore_id by default - last
    clear <file_name>                   clear all backups for selected file (if file not specified, remove all backups for current directory)
"

init_backuper() {
    if [ ! -d "$backup_dir" ]; then
        mkdir $backup_dir
        chmod 770 $backup_dir
    fi
}

get_timestamp() {
    timestamp=$( date +%s)
}

get_date_from_timestamp() {
    local stamp=$1
    date=$(date -d @$stamp)
}

# source: https://github.com/gdbtek/linux-cookbooks/blob/master/libraries/util.bash
function printTable()
{
    local -r delimiter="${1}"
    local -r data="$(removeEmptyLines "${2}")"
    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]
    then
        local -r numberOfLines="$(wc -l <<< "${data}")"
        if [[ "${numberOfLines}" -gt '0' ]]
        then
            local table=''
            local i=1
            for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
            do
                local line=''
                line="$(sed "${i}q;d" <<< "${data}")"
                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"
                if [[ "${i}" -eq '1' ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
                table="${table}\n"
                local j=1
                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
                do
                    table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                done
                table="${table}#|\n"
                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done
            if [[ "$(isEmptyString "${table}")" = 'false' ]]
            then
                echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1'
            fi
        fi
    fi
}

function removeEmptyLines()
{
    local -r content="${1}"
    echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString()
{
    local -r string="${1}"
    local -r numberToRepeat="${2}"
    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]
    then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function isEmptyString()
{
    local -r string="${1}"
    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi
    echo 'false' && return 1
}

function trimString()
{
    local -r string="${1}"
    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}

backup_file() {
    init_backuper
    if [ ! -e "$selected_file" ]; then
        echo -e "${RED}File or directory not exist${NC}"
        exit 1
    fi
    get_timestamp
    backup_path="${backup_dir}/${selected_file}_${timestamp}"
    if [ ! -e  ${backup_path} ]; then
       cp -r ${selected_file} ${backup_path}
    fi
    echo -e "${GREEN}${selected_file} successfully saved${NC}"
}

get_backups_list() {
    backup_timestamps=()
    while IFS=  read -r -d $'\0'; do
        backup_timestamp="$(cut -d'_' -f2 <<<"$REPLY")"
        backup_timestamps+=("$backup_timestamp")
    done < <(find ${backup_dir} -name "${selected_file}_*" -print0)
    sorted=( $( printf "%s\n" "${backup_timestamps[@]}" | sort -n ) )
}

get_all_info() {
    all_backups=()
    echo -e "Backups list for ${GREEN}${curr_dir}${NC}:"
    while IFS=  read -r -d $'\0'; do
        f="$(cut -d'_' -f1 <<<"$REPLY")"
        f=${f##*/}
        all_backups+=("$f")
    done < <(find "${backup_dir}" -maxdepth 1 -mindepth 1 -print0)
    sorted_unique=($(echo "${all_backups[@]}" | tr ' ' '\n' | uniq -c | sort -nr | tr '\n' ' '))
    table='NAME,COUNT\n'
    for((i=0; i < ${#sorted_unique[@]}; i+=2))
    do
        part=( "${sorted_unique[@]:i:2}" )
        table="${table}\n${part[1]},${part[0]}"
    done
    printTable ',' "$(echo -e $table)"
}

get_info() {
    init_backuper
    if [ -z "$selected_file" ]; then
        get_all_info
        exit 1
    fi
    selected_file=$(echo "$selected_file" | tr -d '/')
    get_backups_list
    echo -e "Available backups for ${GREEN}${selected_file}${NC}:"
    table='RESTORE_ID,DATE\n'
    for((i=0;i<${#sorted[@]};i++))
    do
        get_date_from_timestamp ${sorted[$i]}
        table="${table}\n${i},${date}"
    done
    printTable ',' "$(echo -e $table)"
}

restore_file() {
    local id="$1"
    local required_timestamp=${sorted[${id}]}
    if [ -d "$curr_dir/${selected_file}" ]; then
        rm -rf "$curr_dir/${selected_file}"
    fi
    mv -f "$backup_dir/${selected_file}_${required_timestamp}" "$curr_dir/${selected_file}"
    echo -e "${GREEN}${selected_file} successfully restored${NC}"
}

restore() {
    init_backuper
    get_backups_list
    if [ ! -z "$restore_id" ]; then
        if [ -z "${restore_id##*[!0-9]*}" ]; then
            echo -e "${RED}Wrong${NC} restore_id ${RED}format (must be integer)${NC}" 
            exit 1
        fi
        if [ "$restore_id" -ge 0 ] && [ "$restore_id" -lt "${#sorted[@]}" ] ; then
            restore_file $restore_id
        else
            echo -e "${RED}Backup with selected ${NC}restore_id${RED} not found${NC}"
            echo "$usage" >&2
            exit 1
        fi
    else
        local last_id=$(( ${#sorted[@]}-1 )) 
        restore_file $last_id
    fi
}

clear() {
    if [ -z "$selected_file" ]; then
        rm -rf $backup_dir
        echo -e "${GREEN}Backup directory successfully removed${NC}"
    else
        selected_file=$(echo "$selected_file" | tr -d '/')
        find $backup_dir -name "${selected_file}*" -exec rm -rf {} \; 2>/dev/null 
    fi
}

validate_filename() {
    if [ -z "$selected_file" ]; then
        echo -e "${RED}Require ${NC}<file_name>${RED} parameter${NC}"
        echo "$usage" >&2
        exit 1
    fi
    selected_file=$(echo "$selected_file" | tr -d '/')
}

key="$1"

case $key in
    info|i)
    selected_file="$2"
    get_info
    ;;
    backup|b)
    selected_file="$2"
    validate_filename
    backup_file
    ;;
    restore|r)
    selected_file="$2"
    restore_id="$3"
    validate_filename
    restore
    ;;
    clear|c)
    selected_file="$2"
    clear
    ;;
    *)
    echo "$usage" >&2
    exit 1
    ;;
esac

