#!/bin/sh

DESCRIPTION=$(ubus call system board | jsonfilter -e '@.release.description')
VERSION=$(ubus call system board | jsonfilter -e '@.release.version')
findVersion="24.10.2"

if printf '%sn%sn' "$findVersion" "$VERSION" | sort -V | tail -n1 | grep -qx -- "$VERSION"; then
 printf "033[32;1mThis new firmware. Running new scprit...033[0mn"
 wget --no-check-certificate -O /tmp/universal_config_new_podkop.sh https://raw.githubusercontent.com/gangstap/283r2jhr3h28o/refs/heads/main/universal_config_new_podkop.sh && chmod +x /tmp/universal_config_new_podkop.sh && /tmp/universal_config_new_podkop.sh $1 $2
else
 printf "033[32;1mThis old firmware.nRecommendation, upgrade firmware to actual release...nSleep 5 sec...033[0mn"
 sleep 5
 printf "033[32;1mRunning old scprit...033[0mn"
 wget --no-check-certificate -O /tmp/universal_config.sh https://raw.githubusercontent.com/gangstap/283r2jhr3h28o/refs/heads/main/universal_config.sh && chmod +x /tmp/universal_config.sh && /tmp/universal_config.sh $1 $2
fi