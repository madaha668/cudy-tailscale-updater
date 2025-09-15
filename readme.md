# Using Tiny Tailscale in CUDY routers

## About CUDY routers

[CUDY Routers](https://www.cudy.com/en-us/collections/wi-fi-routers), especially the small portable models like [TR3000](https://www.cudy.com/en-us/products/tr3000-1-0), and [TR1200](https://www.cudy.com/en-us/products/tr1200-1-0) are very cost efficient.

However its official router software doesn't contain tailscale application. Luckily the CUDY vendor provides the [approach](https://www.cudy.com/en-us/blogs/faq/openwrt-software-download) to re-flash the gears with openwrt, and I have just verified it with a TR3000 box (openwrt 24.10.2).

## Why this project matters
Firstly, the root filesystem in TR3000 running openwrt is rather small(<50MB), openwrt official release of combined tailscale and tailscaled is around 20MB +, and Tailscale official arm64 release is even much bigger. To save the space, I need a more compact one.

Secondly, the openwrt tailscale version is lagging far from the Tailscale official. To keep the tailscale in CUDY router uptodate, it's necessary to construct a fresh version. 

## Install official openwrt for CUDY routers

* the followings are based on CUDY *TR3000*
* power on it
* download the intermeidate openwrt by CUDY from google drive
* flash the CUDY router with the [intermediate openwrt firmware](https://drive.google.com/drive/folders/1BKVarlwlNxf7uJUtRhuMGUqeCa5KpMnj)
* wait flash down and reboot
* login the web UI of the intermediate openwrt
* download the latest openwrt for cortex53
* BACKUP the partitions of the router following CUDY's suggestion!
* flash it again with the latest openwrt binary
* wait it to reboot and ssh login it after allset
* some tweaks
  * install some pkgs: curl, jq, bash and ip6tables
  * install openwrt tailscale with opkg <---- we might have to skip the step in routers with very limited storage space like TR1200
    * it might be necessary to construct all the configuration files for tailscale(d) to run, manually !!!
  * wrap the wget with 'wget -4' if 'opkg update' failed for [this issue](https://www.reddit.com/r/openwrt/comments/1j7862n/wget_returned_4_failed_to_download_a_package/)
  * run 'download-tiny\_tailscale.sh' to get the tiny tailscale(d) in /tmp/tailscale directory of the openwrt router
  * stop tailscaled service if it's running
  * replace the /usr/sbin/tailscaled with that in /tmp/tailscale/
  * restart the tailscaled service
* login the luci web UI
* configure tailscale follwing the [guide](https://openwrt.org/docs/guide-user/services/vpn/tailscale/start) and up it!

## TODO
To verify the work with TR1200.

## Disclaimer (copy from https://github.com/Admonstrator/glinet-tailscale-updater)
This script is provided as is and without any warranty. Use it at your own risk.

It may break your router, your computer, your network or anything else. It may even burn down your house.

You have been warned!

## Acknowledges

Thanks to [Admonstrator](https://github.com/Admonstrator) for the glinet-tailscale-updater project!

Thanks to [lwbt](https://github.com/lwbt) for the UPX compression & the tiny-tailscale feature!
