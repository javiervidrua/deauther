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

## FUNCTIONS
# Checks the arguments passed to the tool
function checkArguments(){
        if [ $# -ne 1 ];then
                usage
                return 1
        fi
        return 0
}

# Check if the system meets the required dependencies
function checkDependencies(){
        if [ -z $(which macchanger) ]; then
                echo "[-] You need to have installed macchanger"
                return 1
        fi
        if [ -z $(which aircrack-ng) ]; then
                echo "[-] You need to have installed aircrack-ng"
                return 1
        fi
        return 0
}

# Checks the exit code of the functions and if not, ouputs error message and exits
function checkExitCode(){
        if [ $1 -ne 0 ]; then
                echo "[-] Error: $2"
                exit
        else
                return 0
        fi
}

# Checks if the wireless interface is in monitor mode
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

# Checks if the wireless interface provided is available
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

# Puts the wireless interface in monitor mode
function monitorMode(){
        trap '' 2
        INTERFACE=$1
        echo "[*] Putting interface ${INTERFACE} in monitor mode"
        ifconfig ${INTERFACE} down && iwconfig ${INTERFACE} mode monitor && ifconfig ${INTERFACE} up && echo "[*] Interface ${INTERFACE} is now on monitor mode" && return 0 || checkExitCode $? "monitorMode"
}

# Puts the wireless interface in managed mode
function managedMode(){
        trap '' 2
        INTERFACE=$1
        echo "[*] Putting interface ${INTERFACE} in managed mode"
        ifconfig ${INTERFACE} down && iwconfig ${INTERFACE} mode managed && ifconfig ${INTERFACE} up && echo "[*] Interface ${INTERFACE} is now on managed mode" && return 0 || checkExitCode $? "managedMode"
}

# Scans for networks and parses the output so we end up with the SSID, frequency, quality and ESSID of the networks, separated by spaces
function scanAndParse(){
        INTERFACE=$1
        SCAN=$(iwlist $INTERFACE scan | grep -E 'Cell|ESSID|Frequency|Quality')

        declare -a NETWORKS
        local COUNTER=-1
        while IFS= read -r LINE; do
                echo $LINE | grep Address >/dev/null 2>&1 && ADDRESS=$(echo $LINE | grep Address)
                if [ $? -eq 0 ]; then
                        let COUNTER++
                fi
                echo $LINE | grep Frequency >/dev/null 2>&1 && FREQUENCY=$(echo $LINE | grep Frequency)
                echo $LINE | grep Quality >/dev/null 2>&1 && QUALITY=$(echo $LINE | grep Quality)
                ESSID=$(echo $LINE | grep ESSID)
                if [ $? -ne 1 ]; then
                        NETWORKS[COUNTER]="$ADDRESS $FREQUENCY $QUALITY $ESSID"
                fi
        done <<< "$SCAN"

        for NETWORK in "${NETWORKS[@]}"; do
                echo $NETWORK
        done

}

# Outputs the usage
function usage(){
        echo "[*] Usage: ./deauther.sh <INTERFACE>"
}

## MAIN
checkArguments $@
checkExitCode $? "checkArguments"

checkDependencies
checkExitCode $? "checkDependencies"

checkWirelessInterface $1
checkExitCode $? "checkWirelessInterface"

# Scan for available networks and send output to file
INTERFACE=$1
scanAndParse $INTERFACE | cut -d ' ' -f 4- > deauther_networks_temp.lst
checkExitCode $? "scanAndParse"
scanAndParse $INTERFACE | cut -d ' ' -f 4- >> deauther_networks_temp.lst
checkExitCode $? "scanAndParse"
scanAndParse $INTERFACE | cut -d ' ' -f 4- >> deauther_networks_temp.lst
checkExitCode $? "scanAndParse"
cat deauther_networks_temp.lst | sort -u > deauther_networks.lst
checkExitCode $? "sortNetworksList"
rm -rf deauther_networks_temp.lst
checkExitCode $? "removeTemporalNetworksList"

# Start sending 20 deauthentication packets to each network (previously put interface in monitor mode)
#   mdk3

exit

checkMonitorMode $INTERFACE
if [ $? -eq 1 ]; then
        monitorMode $INTERFACE
        checkExitCode $? "monitorMode"
fi

echo "[*] Done"
managedMode $INTERFACE
checkExitCode $? "managedMode"
