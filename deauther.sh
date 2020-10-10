#!/usr/bin/env bash

#MIT License

#Copyright (c) 2020 Javier Vidal Ruano

#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:

#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.

#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

# FUNCTIONS
function checkArguments(){
        if [ $# -ne 1 ];then
                usage
                return 1
        fi
        return 0
}

function checkExitCode(){
        if [ $1 -ne 0 ]; then
                echo "[-] Error: $2"
                exit
        else
                return 0
        fi
}

function checkMonitorMode(){
        local INTERFACE=$1
        local MODE=$(iwconfig 2>/dev/null | grep -E "${INTERFACE}" -A1 | grep "Mode" | cut -d ':' -f 2 | cut -d' ' -f1 | cut -d' ' -f1)
        echo "[*] Interface ${INTERFACE} in ${MODE} mode"
        if [ $MODE = 'Monitor' ]; then
                return 0
        else
                return 1
        fi
}

function checkWirelessInterface () {
        local INTERFACE=$1
        local INTERFACE_FOUND=0
        for INT in $(ifconfig -a | sed 's/[ \t].*//;/^$/d' | grep 'w' | tr -d ':'); do
                if [ $INTERFACE = $INT ]; then
                        INTERFACE_FOUND=1
                        break
                fi
        done
        if [ $INTERFACE_FOUND -eq 0 ]; then
                echo "[-] Error: Could not detect any wireless interfaces up and running"
                return 1
        else
                echo "[*] Wireless interface ${INTERFACE} is up and running"
                return 0
        fi
}

function monitorMode(){
        trap '' 2 # SIGINT
        INTERFACE=$1
        echo "[*] Putting interface ${INTERFACE} in monitor mode"
        ifconfig ${INTERFACE} down && iwconfig ${INTERFACE} mode monitor && ifconfig ${INTERFACE} up && echo "[*] Interface ${INTERFACE} is now on monitor mode" && return 0 || checkExitCode $? "monitorMode"
}

function managedMode(){
        trap '' 2 # SIGINT
        INTERFACE=$1
        echo "[*] Putting interface ${INTERFACE} in managed mode"
        ifconfig ${INTERFACE} down && iwconfig ${INTERFACE} mode managed && ifconfig ${INTERFACE} up && echo "[*] Interface ${INTERFACE} is now on managed mode" && return 0 || checkExitCode $? "managedMode"
}

function usage(){
        echo "[*] Usage: ./deauther.sh <INTERFACE>"
}

# MAIN
checkArguments $@
checkExitCode $? "checkArguments"

checkWirelessInterface $1
checkExitCode $? "checkWirelessInterface"

INTERFACE=$1
checkMonitorMode $INTERFACE
if [ $? -eq 1 ]; then
        monitorMode $INTERFACE
        checkExitCode $? "monitorMode"
fi

# use to get the SSIDs:
#   sudo iw dev wlan0 scan | egrep "signal:|SSID:" | sed -e "s/\tsignal: //" -e "s/\tSSID: //" | awk '{ORS = (NR % 2 == 0)? "\n" : " "; print}' | sort

# use to deauth
#   mdk3

echo "[*] Done"
managedMode $INTERFACE
checkExitCode $? "managedMode"
