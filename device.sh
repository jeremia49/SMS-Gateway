#!/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/config.env"
_DEVICEAPI_=$MODEMHOST

__SESINFO__=""
__TOKINFO__=""


__PASSWORDHASH__=''

function initializeCookie(){
    local req=$(curl -s -I -X GET $_DEVICEAPI_/html/home.html | grep -i set-cookie)
    local session=$(echo -n $req | cut -d'=' -f2 | cut -d';' -f1)
    __SESINFO__=$session
    return 0
}


function getSesTokInfo(){
    keepSessionID=$1
    __TOKINFO__=''
    curl -s "$_DEVICEAPI_/api" >/dev/null 2>&1;
    if [[ $? -eq 0 ]]
    then
        
        if [[ $keepSessionID -ne 1 ]]; then
            __SESINFO__=''
            # echo "Delete Session"
            initializeCookie
        fi
        local req=$(
                curl -s $_DEVICEAPI_/api/webserver/SesTokInfo \
                -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/112.0' \
                -H "Cookie: ${__SESINFO__}" 
        )
        __SESINFO__=$(echo $req | grep -oP '(?<=<SesInfo>).*(?=<\/SesInfo>)')
        __TOKINFO__=$(echo $req | grep -oP '(?<=<TokInfo>).*(?=<\/TokInfo>)')
        # echo $__SESINFO__
        return 0
    else
        echo "Gagal mendapatkan Session dan Token Info"
        return -1
    fi
}

function hashPassword(){
    __PASSWORDHASH__=''
    local username=$1
    local password=$2
    local token=$3
    # psd = base64encode(SHA256(name + base64encode(SHA256($('#password').val())) + g_requestVerificationToken[0]));
    local p1=$(echo -n "$password" | sha256sum | awk '{print $1}' | tr -d \\n | base64 | tr -d \\n)
    if [[ $? -ne 0 ]]; then
        return -1
    fi
    # echo $p1
    local p2="$username$p1$token"
    if [[ $? -ne 0 ]]; then
        return -1
    fi
    # echo $p2
    local p3="$(echo -n $p2 | sha256sum | awk '{print $1}')"
    if [[ $? -ne 0 ]]; then
        return -1
    fi
    # echo $p3
    local p4="$(echo -n $p3 | base64 | tr -d \\n )"
    if [[ $? -ne 0 ]]; then
        return -1
    fi
    # echo $p4
    __PASSWORDHASH__=$p4
    # echo $__PASSWORDHASH__
    return 0
}


function login(){
    local username=$1
    local password=$2
    getSesTokInfo 0
    if [[ $? -eq 0 ]]
    then
        # echo "Login dengan username" $username "dan password" $password
        hashPassword $username $password $__TOKINFO__

        local req=$(curl -is $_DEVICEAPI_/api/user/login \
            -X POST \
            -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/112.0' \
            -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
            -H "__RequestVerificationToken: ${__TOKINFO__}" \
            -H "Cookie: ${__SESINFO__}" \
            --data-raw "<?xml version="1.0" encoding="UTF-8"?><request><Username>${username}</Username><Password>${__PASSWORDHASH__}</Password><password_type>4</password_type></request>"
        )
        
        if echo $req | grep -qi "error"; then
            echo "Gagal login"
        fi

        local getCookieHeader=$(echo "${req}" | grep -i set-cookie)
        local getSession=$(echo -n $getCookieHeader | cut -d'=' -f2 | cut -d';' -f1)
        __SESINFO__=$getSession
        echo "Login Berhasil"
        return 0
    else
        return -1
    fi
    
}

function sendSMS(){
    local phone=$1
    local content=$2
    local contentlen=${#content}
    local nowdate=$(date +"%Y-%m-%d %H:%M:%S")
    login $USERNAME $PASSWORD
    if [[ $? -eq 0 ]]
    then
        getSesTokInfo 1
        local req=$(curl -s $_DEVICEAPI_/api/sms/send-sms \
            -X POST \
            -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
            -H "__RequestVerificationToken: ${__TOKINFO__}" \
            -H "Cookie: ${__SESINFO__}" \
            --data-raw "<?xml version=1.0 encoding=UTF-8?><request><Index>-1</Index><Phones><Phone>${phone}</Phone></Phones><Sca></Sca><Content>${content}</Content><Length>${contentlen}</Length><Reserved>1</Reserved><Date>${nowdate}</Date></request>"
        )
        if echo $req | grep -qi "error"; then
            echo "Gagal mengirim pesan"
            return -1
        fi
        return 0
    else
        return -1
    fi
    
}

# sendSMS "xxxx" "Baik, terimakasih !!"
# getInitializeCookie
