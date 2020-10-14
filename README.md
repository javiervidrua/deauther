# deauther
802.11b/g deauther.

## What does it do?
* Checks if the system meets the required dependencies
* Checks if the wireless interface is up and running
* Scans for all the available networks and creates a list
* Randomizes the MAC of the wireless interface
* Changes the mode of the wireless interface to monitor mode
* Attacks each network in the list with 5 (default number) deauthentication packets
* Resets the MAC of the wireless interface to the hardware MAC
* Changes the mode of the wireless interface to managed mode
* Restarts the networking services to enable internet connectivity

## Usage
`./deauther <INTERFACE> <WHITELISTED_ESSID>`

## Example
`./deauther wlan0 MyPersonalWiFi`
