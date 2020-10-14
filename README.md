# deauther
*802.11b/g/n* deauther. Kicks out of the network every device connected to it using a deauthentication attack.

To be a able to run the tool you'll need a wireless network interface that has a chip that supports **monitor mode**.

In my case I have an *Alfa Network AWUS036H* and works fine.

## What does it do?
* Checks if the system meets the required dependencies
* Checks if the wireless interface is up and running
* Scans for all the available networks and creates a list
* Randomizes the *MAC* of the wireless interface
* Changes the mode of the wireless interface to monitor mode
* Attacks each network in the list with 5 (default number) deauthentication packets
* Resets the *MAC* of the wireless interface to the hardware *MAC*
* Changes the mode of the wireless interface to managed mode
* Restarts the networking services to enable internet connectivity

## Usage
`./deauther <INTERFACE> [WHITELISTED_ESSID]`

## Example
`./deauther wlan0 MyPersonalWiFi`
