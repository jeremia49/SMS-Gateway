#!/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/config.env"
source "$(dirname "${BASH_SOURCE[0]}")/device.sh"

_QUEUEHOST_=$APIHOST
__QUEUENOW__=-1
__QUEUENUMBER__=-1
__QUEUECONTENT__=""



function getLatestQueue(){
    __QUEUENOW__=-1
    curl -s "$_QUEUEHOST_/ping" >/dev/null 2>&1; #cek koneksi
    if [[ $? -eq 0 ]]
    then
        local req=$(curl -sk "$_QUEUEHOST_/api/sms?queue=1&asText=1")
        local firstQ=$(echo $req |awk -F ',' '{print $1}')
        if [[ ! -z "$firstQ" && "$firstQ" -ge 1 ]] 
        then
            __QUEUENOW__=$(echo $firstQ)
        else
            __QUEUENOW__=-1
        fi
        return 0
    else
        return -1
    fi
}

function getMessageContent(){
    __QUEUENUMBER__=-1
    __QUEUECONTENT__=""
    local req=$(curl -sk "$_QUEUEHOST_/api/getSMS/$__QUEUENOW__?asText=1")
    if [[ ! -z "$req" ]]
    then
        __QUEUENUMBER__=$(echo $req |awk -F ',' '{print $1}')
        __QUEUECONTENT__=$(echo $req | awk -F ',' '{print substr($0, length($1)+2)}')
        return 0
    fi
    return -1
}

function announceACK(){
    local req=$(curl -sk "$_QUEUEHOST_/api/procSMS/$__QUEUENOW__?asText=1")
    if [[ (! -z "$req") && ($req == "1")]]
    then
        return 0
    fi
    return -1
}


function announceSuccess(){
    local req=$(curl -sk "$_QUEUEHOST_/api/setSuccess/$__QUEUENOW__?asText=1")
    if [[ (! -z "$req") && ($req == "1")]]
    then
        return 0
    fi
    return -1
}

function announceFailed(){
    local req=$(curl -sk "$_QUEUEHOST_/api/setFailed/$__QUEUENOW__?asText=1")
    if [[ (! -z "$req") && ($req == "1")]]
    then
        return 0
    fi
    return -1
}

function main() {
    while [ 1==1 ]
    do
        getLatestQueue
        status=$?
        if [[ $status -ne 0 ]]
        then
            echo "Gagal konek ke server Queue"
            sleep 5
        else
            if [[ (__QUEUENOW__ != -1) && __QUEUENOW__  -gt 0 ]] 
            then
                echo "Ada pesan"
                getMessageContent
                status=$?
                if [[ $status -ne 0 ]]
                then
                    echo "Gagal mengambil data SMS"
                    sleep 2
                else
                    echo $__QUEUENUMBER__
                    echo $__QUEUECONTENT__
                    announceACK
                    status=$?
                    if [[ $status -ne 0 ]]
                    then
                        echo "Gagal announce ACK"
                        sleep 2
                    else
                        sendSMS $__QUEUENUMBER__ $__QUEUECONTENT__
                        status=$?
                        if [[ $status -ne 0 ]]
                        then
                            echo "Gagal mengirim SMS"
                            announceFailed
                            sleep 2
                        else
                            announceSuccess
                            sleep 5
                        fi
                    fi
                fi
            else
                echo 'tidak ada pesan'
                sleep 2
            fi
        fi
    done
}

main