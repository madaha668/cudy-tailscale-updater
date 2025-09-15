# Using Tiny Tailscale in CUDY routers

## About CUDY routers

[CUDY Routers](https://www.cudy.com/en-us/collections/wi-fi-routers), especially the small portable models like [TR3000](https://www.cudy.com/en-us/products/tr3000-1-0), and [TR1200](https://www.cudy.com/en-us/products/tr1200-1-0) are very cost efficient.

However its official router software doesn't contain tailscale application. Luckily the CUDY vendor provides the [approach](https://www.cudy.com/en-us/blogs/faq/openwrt-software-download) to re-flash the gears with openwrt, and I have just verified it with a TR3000 box (openwrt 24.10.2).

## Why this project matters
Firstly, the root filesystem in TR3000 running openwrt is rather small(<50MB), openwrt official release of combined tailscale and tailscaled is around 20MB +, and Tailscale official arm64 release is even much bigger. To save the space, I need a more compact one.

Secondly, the openwrt tailscale version is lagging far from the Tailscale official. To keep the tailscale in CUDY router uptodate, it's necessary to construct a fresh version. 

## Install official openwrt for CUDY routers

## TODO
To verify the work with TR1200.

## Disclaimer
This script is provided as is and without any warranty. Use it at your own risk.

It may break your router, your computer, your network or anything else. It may even burn down your house.

You have been warned!

## Acknowledges

Thanks to [Admonstrator](https://github.com/Admonstrator) for the glinet-tailscale-updater project!

Thanks to [lwbt](https://github.com/lwbt) for the UPX compression & the tiny-tailscale feature!
