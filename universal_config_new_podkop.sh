#!/bin/sh

# Переменные для резервного копирования и конфигов
DIR_BACKUP="/root/podkop"
DIR="/etc/config"
config_files="dhcp firewall"

# Ссылка на ОРИГИНАЛЬНЫЙ репозиторий для загрузки конфигов и пакетов (Вариант А)
URL="https://raw.githubusercontent.com/routerich/RouterichAX3000_configs/refs/heads/zapret2"

install_awg_packages() {
 PKGARCH=$(opkg print-architecture | awk 'BEGIN {max=0} {if ($3 > max) {max = $3; arch = $2}} END {print arch}')
 TARGET=$(ubus call system board | jsonfilter -e '@.release.target' | cut -d '/' -f 1)
 SUBTARGET=$(ubus call system board | jsonfilter -e '@.release.target' | cut -d '/' -f 2)
 VERSION=$(ubus call system board | jsonfilter -e '@.release.version')
 PKGPOSTFIX="_v${VERSION}_${PKGARCH}_${TARGET}_${SUBTARGET}.ipk"
 BASE_URL="https://github.com/Slava-Shchipunov/awg-openwrt/releases/download/"

 AWG_DIR="/tmp/amneziawg"
 mkdir -p "$AWG_DIR"

 if opkg list-installed | grep -q kmod-amneziawg; then
 echo "kmod-amneziawg already installed"
 else
 KMOD_AMNEZIAWG_FILENAME="kmod-amneziawg${PKGPOSTFIX}"
 DOWNLOAD_URL="${BASE_URL}v${VERSION}/${KMOD_AMNEZIAWG_FILENAME}"
 wget -O "$AWG_DIR/$KMOD_AMNEZIAWG_FILENAME" "$DOWNLOAD_URL"
 if [ $? -eq 0 ]; then
  opkg install "$AWG_DIR/$KMOD_AMNEZIAWG_FILENAME"
 else
  echo "Error downloading kmod-amneziawg."
  exit 1
 fi
 fi

 if opkg list-installed | grep -q amneziawg-tools; then
 echo "amneziawg-tools already installed"
 else
 AMNEZIAWG_TOOLS_FILENAME="amneziawg-tools${PKGPOSTFIX}"
 DOWNLOAD_URL="${BASE_URL}v${VERSION}/${AMNEZIAWG_TOOLS_FILENAME}"
 wget -O "$AWG_DIR/$AMNEZIAWG_TOOLS_FILENAME" "$DOWNLOAD_URL"
 if [ $? -eq 0 ]; then
  opkg install "$AWG_DIR/$AMNEZIAWG_TOOLS_FILENAME"
 else
  echo "Error downloading amneziawg-tools."
  exit 1
 fi
 fi

 if opkg list-installed | grep -q luci-app-amneziawg; then
 echo "luci-app-amneziawg already installed"
 else
 LUCI_APP_AMNEZIAWG_FILENAME="luci-app-amneziawg${PKGPOSTFIX}"
 DOWNLOAD_URL="${BASE_URL}v${VERSION}/${LUCI_APP_AMNEZIAWG_FILENAME}"
 wget -O "$AWG_DIR/$LUCI_APP_AMNEZIAWG_FILENAME" "$DOWNLOAD_URL"
 if [ $? -eq 0 ]; then
  opkg install "$AWG_DIR/$LUCI_APP_AMNEZIAWG_FILENAME"
 else
  echo "Error downloading luci-app-amneziawg."
  exit 1
 fi
 fi
 rm -rf "$AWG_DIR"
}

manage_package() {
 local name="$1"
 local autostart="$2"
 local process="$3"
 if opkg list-installed | grep -q "^$name"; then
  if /etc/init.d/$name enabled; then
   [ "$autostart" = "disable" ] && /etc/init.d/$name disable
  else
   [ "$autostart" = "enable" ] && /etc/init.d/$name enable
  fi
  if pidof $name > /dev/null; then
   [ "$process" = "stop" ] && /etc/init.d/$name stop
  else
   [ "$process" = "start" ] && /etc/init.d/$name start
  fi
 fi
}

checkPackageAndInstall() {
 local name="$1"
 local isRequired="$2"
 local alt=""
 [ "$name" = "https-dns-proxy" ] && alt="luci-app-doh-proxy"

 if [ -n "$alt" ]; then
  opkg list-installed | grep -qE "^($name|$alt) " && { echo "$name or $alt already installed..."; return 0; }
 else
  opkg list-installed | grep -q "^$name " && { echo "$name already installed..."; return 0; }
 fi

 echo "$name not installed. Installing $name..."
 opkg install "$name"
 if [ "$isRequired" = "1" ] && [ $? -ne 0 ]; then
  echo "Error installing $name. Please install manually."
  exit 1
 fi
}

requestConfWARP1() {
 # Прямой URL без hex-кодирования (работает в BusyBox)
 COMPILE="https://santa-atmo.ru/warp/warp.php"
 curl --connect-timeout 20 --max-time 60 -w "%{http_code}" "$COMPILE" \
 -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36' \
 -H "referer: $COMPILE" -H "Origin: $COMPILE"
}

requestConfWARP2() {
 curl --connect-timeout 20 --max-time 60 -w "%{http_code}" 'https://dulcet-fox-556b08.netlify.app/api/warp' \
 -H 'Accept: */*' -H 'Content-Type: application/json' \
 --data-raw '{"selectedServices":[],"siteMode":"all","deviceType":"computer","endpoint":"162.159.195.1:500"}'
}

requestConfWARP3() {
 curl --connect-timeout 20 --max-time 60 -w "%{http_code}" 'https://warp-config-generator-theta.vercel.app/api/warp' \
 -H 'Accept: */*' -H 'Content-Type: application/json' \
 --data-raw '{"selectedServices":[],"siteMode":"all","deviceType":"computer","endpoint":"162.159.195.1:500"}'
}

requestConfWARP4() {
 curl --connect-timeout 20 --max-time 60 -w "%{http_code}" 'https://generator-warp-config.vercel.app/warp4s?dns=1.1.1.1%2C%201.0.0.1%2C%202606%3A4700%3A4700%3A%3A1111%2C%202606%3A4700%3A4700%3A%3A1001&allowedIPs=0.0.0.0%2F0%2C%20%3A%3A%2F0' \
 -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36'
}

requestConfWARP5() {
 curl --connect-timeout 20 --max-time 60 -w "%{http_code}" 'https://valokda-amnezia.vercel.app/api/warp' \
 -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36'
}

requestConfWARP6() {
 curl --connect-timeout 20 --max-time 60 -w "%{http_code}" 'https://warp-gen.vercel.app/generate-config' \
 -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36'
}

requestConfWARP7() {
 curl --connect-timeout 20 --max-time 60 -w "%{http_code}" 'https://config-generator-warp.vercel.app/warps' \
 -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36'
}

requestConfWARP8() {
 curl --connect-timeout 20 --max-time 60 -w "%{http_code}" 'https://config-generator-warp.vercel.app/warp6s' \
 -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36'
}

requestConfWARP9() {
 curl --connect-timeout 20 --max-time 60 -w "%{http_code}" 'https://config-generator-warp.vercel.app/warp4s' \
 -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36'
}

requestConfWARP10() {
 curl --connect-timeout 20 --max-time 60 -w "%{http_code}" 'https://warp-generator.vercel.app/api/warp' \
 -H 'content-type: application/json' \
 --data-raw '{"selectedServices":[],"siteMode":"all","deviceType":"computer"}'
}

confWarpBuilder() {
 response_body=$1
 peer_pub=$(echo "$response_body" | jq -r '.result.config.peers[0].public_key')
 client_ipv4=$(echo "$response_body" | jq -r '.result.config.interface.addresses.v4')
 client_ipv6=$(echo "$response_body" | jq -r '.result.config.interface.addresses.v6')
 priv=$(echo "$response_body" | jq -r '.result.key')
 cat << EOM
[Interface]
PrivateKey = ${priv}
S1 = 0
S2 = 0
Jc = 120
Jmin = 23
Jmax = 911
H1 = 1
H2 = 2
H3 = 3
H4 = 4
MTU = 1280
Address = ${client_ipv4}, ${client_ipv6}
DNS = 1.1.1.1, 2606:4700:4700::1111, 1.0.0.1, 2606:4700:4700::1001

[Peer]
PublicKey = ${peer_pub}
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = 162.159.192.1:500
EOM
}

check_request() {
 local response="$1"
 local choice="$2"
 local response_code="${response: -3}"
 local response_body="${response%???}"
 
 if [ "$response_code" -eq 200 ]; then
  case $choice in
   1) confWarpBuilder "$response_body" ;;
   2|3|10) echo "$response_body" | jq -r '.content' | jq -r '.configBase64' | base64 -d ;;
   4|5|7|8|9) echo "$response_body" | jq -r '.content' | base64 -d ;;
   6) echo "$response_body" | jq -r '.config' ;;
   *) echo "Error" ;;
  esac
 else
  echo "Error"
 fi
}

checkAndAddDomainPermanentName() {
 nameRule="option name '$1'"
 if ! grep -qi "$nameRule" /etc/config/dhcp; then
  uci add dhcp domain
  uci set dhcp.@domain[-1].name="$1"
  uci set dhcp.@domain[-1].ip="$2"
  uci commit dhcp
 fi
}

byPassGeoBlockXboxDNS() {
 uci set dhcp.cfg01411c.strictorder='1'
 uci set dhcp.cfg01411c.filter_aaaa='1'
 uci del dhcp.cfg01411c.server
 uci add_list dhcp.cfg01411c.server='127.0.0.1#5359'
 uci add_list dhcp.cfg01411c.server='/*.chatgpt.com/127.0.0.1#5056'
 uci add_list dhcp.cfg01411c.server='/*.openai.com/127.0.0.1#5056'
 uci add_list dhcp.cfg01411c.server='/*.microsoft.com/127.0.0.1#5056'
 uci add_list dhcp.cfg01411c.server='/*.xbox.com/127.0.0.1#5056'
 uci add_list dhcp.cfg01411c.server='/*.xboxlive.com/127.0.0.1#5056'
 uci commit dhcp
 service dnsmasq restart
 service odhcpd restart
}

deleteByPassGeoBlockXboxDNS() {
 uci del dhcp.cfg01411c.server
 uci add_list dhcp.cfg01411c.server='127.0.0.1#5359'
 while uci del dhcp.@domain[-1] ; do : ; done
 uci commit dhcp
 service dnsmasq restart
 service odhcpd restart
}

if [ "$1" = "y" ] || [ "$1" = "Y" ]; then
 is_manual_input_parameters="y"
else
 is_manual_input_parameters="n"
fi

if [ "$2" = "y" ] || [ "$2" = "Y" ] || [ "$2" = "" ]; then
 is_reconfig_podkop="y"
else
 is_reconfig_podkop="n"
fi

echo "Update list packages..."
opkg update

checkPackageAndInstall "coreutils-base64" "1"
checkPackageAndInstall "https-dns-proxy" "0"

if [ ! -d "$DIR_BACKUP" ]; then
 echo "Backup files..."
 mkdir -p "$DIR_BACKUP"
 for file in $config_files; do
  cp -f "$DIR/$file" "$DIR_BACKUP/$file"
 done
 echo "Replace configs..."
 for file in $config_files; do
  [ "$file" = "https-dns-proxy" ] && wget -O "$DIR/$file" "$URL/config_files/$file"
 done
fi

echo "Configure dhcp..."
uci set dhcp.cfg01411c.strictorder='1'
uci set dhcp.cfg01411c.filter_aaaa='1'
uci commit dhcp

mkdir -p /etc/sing-box
cat << EOF > /etc/sing-box/config.json
{
  "log": { "disabled": true, "level": "error" },
  "inbounds": [ { "type": "tproxy", "listen": "::", "listen_port": 1100, "sniff": false } ],
  "outbounds": [ { "type": "http", "server": "127.0.0.1", "server_port": 18080 } ],
  "route": { "auto_detect_interface": true }
}
EOF

echo "Setting sing-box..."
uci set sing-box.main.enabled='1'
uci set sing-box.main.user='root'
uci add_list sing-box.main.ifaces='wan'
uci add_list sing-box.main.ifaces='wan6'
uci commit sing-box

if ! grep -qi "option name 'Block_UDP_443'" /etc/config/firewall; then
 uci add firewall rule
 uci set firewall.@rule[-1].name='Block_UDP_443'
 uci add_list firewall.@rule[-1].proto='udp'
 uci set firewall.@rule[-1].src='lan'
 uci set firewall.@rule[-1].dest='wan'
 uci set firewall.@rule[-1].dest_port='443'
 uci set firewall.@rule[-1].target='REJECT'
 uci commit firewall
fi

printf "\033[32;1mCheck work youtubeUnblock..\033[0m\n"
opkg upgrade youtubeUnblock luci-app-youtubeUnblock 2>/dev/null
manage_package "youtubeUnblock" "enable" "start"
wget -O "/etc/config/youtubeUnblock" "$URL/config_files/youtubeUnblockSecond" 2>/dev/null
manage_package "podkop" "enable" "stop"
service youtubeUnblock restart 2>/dev/null

isWorkYoutubeUnBlock=0
if curl -f -o /dev/null -k --connect-to ::google.com -L -H "Host: mirror.gcr.io" --max-time 10 https://test.googlevideo.com/v2/cimg/android/blobs/sha256:6fd8bdac3da660bde7bd0b6f2b6a46e1b686afb74b9a4614def32532b73f5eaa 2>/dev/null; then
 printf "\033[32;1myoutubeUnblock well work...\033[0m\n"
 isWorkYoutubeUnBlock=1
else
 manage_package "youtubeUnblock" "disable" "stop"
 printf "\033[32;1myoutubeUnblock not work...\033[0m\n"
fi

isWorkOperaProxy=0
printf "\033[32;1mCheck opera proxy...\033[0m\n"
service sing-box restart 2>/dev/null
if curl --proxy http://127.0.0.1:18080 -m 5 ipinfo.io/ip >/dev/null 2>&1; then
 printf "\033[32;1mOpera proxy well work...\033[0m\n"
 isWorkOperaProxy=1
else
 printf "\033[32;1mOpera proxy not work...\033[0m\n"
fi

countRepeatAWGGen=2
currIter=0
isExit=0
while [ $currIter -lt $countRepeatAWGGen ] && [ "$isExit" = "0" ]; do
 currIter=$(( $currIter + 1 ))
 printf "\033[32;1mCreate and Check AWG WARP... Attempt #$currIter...\033[0m\n"
 
 if [ "$is_manual_input_parameters" = "y" ] || [ "$is_manual_input_parameters" = "Y" ]; then
  read -r -p "PrivateKey: " PrivateKey
  read -r -p "S1: " S1; read -r -p "S2: " S2
  read -r -p "Jc: " Jc; read -r -p "Jmin: " Jmin; read -r -p "Jmax: " Jmax
  read -r -p "H1: " H1; read -r -p "H2: " H2; read -r -p "H3: " H3; read -r -p "H4: " H4
  read -r -p "Address (e.g., 192.168.100.5/24): " Address
  read -r -p "PublicKey: " PublicKey
  read -r -p "EndpointIP: " EndpointIP
  read -r -p "EndpointPort [51820]: " EndpointPort
  EndpointPort=${EndpointPort:-51820}
  DNS="1.1.1.1"; MTU=1280; AllowedIPs="0.0.0.0/0"
  isExit=1
 else
  warp_config="Error"
  for i in 1 2 3 4 5 6 7 8 9 10; do
   printf "\033[32;1mRequest WARP config... Attempt #$i\033[0m\n"
   result=$(eval "requestConfWARP$i")
   warpGen=$(check_request "$result" "$i")
   if [ "$warpGen" != "Error" ]; then
    warp_config="$warpGen"
    break
   fi
  done

  if [ "$warp_config" = "Error" ]; then
   printf "\033[32;1mGenerate config AWG WARP failed...\033[0m\n"
   isExit=2
  else
   while IFS=' = ' read -r line; do
    if echo "$line" | grep -q "="; then
     key=$(echo "$line" | cut -d'=' -f1 | xargs)
     value=$(echo "$line" | cut -d'=' -f2- | xargs)
     eval "$key=\"$value\""
    fi
   done < <(echo "$warp_config")
   Address=$(echo "$Address" | cut -d',' -f1)
   DNS=$(echo "$DNS" | cut -d',' -f1)
   EndpointIP=$(echo "$Endpoint" | cut -d':' -f1)
   EndpointPort=$(echo "$Endpoint" | cut -d':' -f2)
  fi
 fi

 if [ "$isExit" != "2" ]; then
  INTERFACE_NAME="awg10"
  CONFIG_NAME="amneziawg_awg10"
  uci set network.${INTERFACE_NAME}=interface
  uci set network.${INTERFACE_NAME}.proto="amneziawg"
  uci show network | grep -q "amneziawg_awg10" || uci add network amneziawg_awg10
  uci set network.${INTERFACE_NAME}.private_key="$PrivateKey"
  uci del network.${INTERFACE_NAME}.addresses
  uci add_list network.${INTERFACE_NAME}.addresses="$Address"
  uci set network.${INTERFACE_NAME}.mtu="${MTU:-1280}"
  uci set network.${INTERFACE_NAME}.awg_jc="${Jc:-120}"
  uci set network.${INTERFACE_NAME}.awg_jmin="${Jmin:-23}"
  uci set network.${INTERFACE_NAME}.awg_jmax="${Jmax:-911}"
  uci set network.${INTERFACE_NAME}.awg_s1="${S1:-0}"
  uci set network.${INTERFACE_NAME}.awg_s2="${S2:-0}"
  uci set network.${INTERFACE_NAME}.awg_h1="${H1:-1}"
  uci set network.${INTERFACE_NAME}.awg_h2="${H2:-2}"
  uci set network.${INTERFACE_NAME}.awg_h3="${H3:-3}"
  uci set network.${INTERFACE_NAME}.awg_h4="${H4:-4}"
  uci set network.${INTERFACE_NAME}.nohostroute='1'

  uci set network.@amneziawg_awg10[-1].public_key="$PublicKey"
  uci set network.@amneziawg_awg10[-1].endpoint_host="$EndpointIP"
  uci set network.@amneziawg_awg10[-1].endpoint_port="$EndpointPort"
  uci set network.@amneziawg_awg10[-1].persistent_keepalive='25'
  uci set network.@amneziawg_awg10[-1].allowed_ips='0.0.0.0/0'
  uci set network.@amneziawg_awg10[-1].route_allowed_ips='0'
  uci commit network

  if ! uci show firewall | grep -q "@zone.*name='awg'"; then
   uci add firewall zone
   uci set firewall.@zone[-1].name='awg'
   uci set firewall.@zone[-1].network="$INTERFACE_NAME"
   uci set firewall.@zone[-1].forward='REJECT'
   uci set firewall.@zone[-1].output='ACCEPT'
   uci set firewall.@zone[-1].input='REJECT'
   uci set firewall.@zone[-1].masq='1'
   uci set firewall.@zone[-1].mtu_fix='1'
   uci commit firewall
  fi

  ifdown "$INTERFACE_NAME" 2>/dev/null
  ifup "$INTERFACE_NAME"
  sleep 5

  if ping -c 1 -I "$INTERFACE_NAME" 8.8.8.8 >/dev/null 2>&1; then
   printf "\033[32;1m Endpoint WARP $EndpointIP:$EndpointPort work...\033[0m\n"
   isExit=1
  else
   printf "\033[31;1m Endpoint WARP $EndpointIP:$EndpointPort not work...\033[0m\n"
   isExit=0
  fi
 fi
done

isWorkWARP=0
[ "$isExit" = "1" ] && { printf "\033[32;1mAWG WARP well work...\033[0m\n"; isWorkWARP=1; } || { printf "\033[32;1mAWG WARP not work.....Try opera proxy...\033[0m\n"; }

echo "isWorkYoutubeUnBlock = $isWorkYoutubeUnBlock, isWorkOperaProxy = $isWorkOperaProxy, isWorkWARP = $isWorkWARP"

if [ "$isWorkYoutubeUnBlock" = "1" ] && [ "$isWorkOperaProxy" = "1" ] && [ "$isWorkWARP" = "1" ]; then varByPass=1
elif [ "$isWorkYoutubeUnBlock" = "0" ] && [ "$isWorkOperaProxy" = "1" ] && [ "$isWorkWARP" = "1" ]; then varByPass=2
elif [ "$isWorkYoutubeUnBlock" = "1" ] && [ "$isWorkOperaProxy" = "1" ] && [ "$isWorkWARP" = "0" ]; then varByPass=3
elif [ "$isWorkYoutubeUnBlock" = "0" ] && [ "$isWorkOperaProxy" = "1" ] && [ "$isWorkWARP" = "0" ]; then varByPass=4
elif [ "$isWorkYoutubeUnBlock" = "1" ] && [ "$isWorkOperaProxy" = "0" ] && [ "$isWorkWARP" = "0" ]; then varByPass=5
elif [ "$isWorkYoutubeUnBlock" = "0" ] && [ "$isWorkOperaProxy" = "0" ] && [ "$isWorkWARP" = "1" ]; then varByPass=6
elif [ "$isWorkYoutubeUnBlock" = "1" ] && [ "$isWorkOperaProxy" = "0" ] && [ "$isWorkWARP" = "1" ]; then varByPass=7
else varByPass=8; fi

printf "\033[32;1mRestart service dnsmasq, odhcpd...\033[0m\n"
service dnsmasq restart
service odhcpd restart

path_podkop_config="/etc/config/podkop"
path_podkop_config_backup="/root/podkop"
messageComplete=""

case $varByPass in
 1) nameFileReplacePodkop="podkopNewNoYoutube"; manage_package "ruantiblock" "disable" "stop"; manage_package "youtubeUnblock" "disable" "stop"; manage_package "zapret" "disable" "stop"; service zapret2 restart 2>/dev/null; deleteByPassGeoBlockXboxDNS; messageComplete="Method 1: AWG WARP + zapret2 + Opera Proxy" ;;
 2) nameFileReplacePodkop="podkopNew"; manage_package "youtubeUnblock" "disable" "stop"; manage_package "ruantiblock" "disable" "stop"; manage_package "zapret" "disable" "stop"; manage_package "zapret2" "disable" "stop"; deleteByPassGeoBlockXboxDNS; messageComplete="Method 2: AWG WARP + Opera Proxy" ;;
 3) nameFileReplacePodkop="podkopNewSecond"; manage_package "ruantiblock" "disable" "stop"; manage_package "youtubeUnblock" "disable" "stop"; manage_package "zapret" "disable" "stop"; service zapret2 restart 2>/dev/null; deleteByPassGeoBlockXboxDNS; messageComplete="Method 3: zapret2 + Opera Proxy" ;;
 4) nameFileReplacePodkop="podkopNewSecondYoutube"; manage_package "youtubeUnblock" "disable" "stop"; manage_package "ruantiblock" "disable" "stop"; manage_package "zapret" "disable" "stop"; manage_package "zapret2" "disable" "stop"; deleteByPassGeoBlockXboxDNS; messageComplete="Method 4: Only Opera Proxy" ;;
 5) nameFileReplacePodkop="podkopNewSecondYoutube"; manage_package "ruantiblock" "disable" "stop"; manage_package "podkop" "disable" "stop"; manage_package "youtubeunblock" "disable" "stop"; manage_package "zapret" "disable" "stop"; wget -O "/opt/zapret2/ipset/zapret_hosts_user.txt" "$URL/config_files/zapret-hosts-user-second.txt" 2>/dev/null; service zapret2 restart 2>/dev/null; byPassGeoBlockXboxDNS; messageComplete="Method 5: zapret2 + XboxDNS" ;;
 6) nameFileReplacePodkop="podkopNewWARP"; manage_package "youtubeUnblock" "disable" "stop"; manage_package "ruantiblock" "disable" "stop"; manage_package "zapret" "disable" "stop"; manage_package "zapret2" "disable" "stop"; byPassGeoBlockXboxDNS; messageComplete="Method 6: AWG WARP + XboxDNS" ;;
 7) nameFileReplacePodkop="podkopNewWARPNoYoutube"; manage_package "ruantiblock" "disable" "stop"; manage_package "youtubeUnblock" "disable" "stop"; manage_package "zapret" "disable" "stop"; service zapret2 restart 2>/dev/null; byPassGeoBlockXboxDNS; messageComplete="Method 7: AWG WARP + zapret2 + XboxDNS" ;;
 8) printf "\033[32;1mTry custom settings... Recommendation: buy VPS and setup vless\033[0m\n"; exit 1 ;;
 *) echo "Unknown error."; exit 1 ;;
esac

PACKAGE="podkop"
REQUIRED_VERSION="v0.7.21-r1"
INSTALLED_VERSION=$(opkg list-installed | grep "^$PACKAGE" | cut -d ' ' -f 3)
if [ -n "$INSTALLED_VERSION" ] && [ "$INSTALLED_VERSION" != "$REQUIRED_VERSION" ]; then
 opkg remove --force-removal-of-dependent-packages "$PACKAGE" 2>/dev/null
fi

if [ -f "/etc/init.d/podkop" ]; then
 if [ "$is_reconfig_podkop" = "y" ] || [ "$is_reconfig_podkop" = "Y" ]; then
  cp -f "$path_podkop_config" "$path_podkop_config_backup"
  wget -O "$path_podkop_config" "$URL/config_files/$nameFileReplacePodkop" 2>/dev/null
  echo "Podkop reconfigured..."
 fi
else
 DOWNLOAD_DIR="/tmp/podkop"
 mkdir -p "$DOWNLOAD_DIR"
 for file in podkop-v0.7.21-r1-all.ipk luci-app-podkop-v0.7.21-r1-all.ipk luci-i18n-podkop-ru-0.7.21.ipk; do
  echo "Download $file..."
  wget -q -O "$DOWNLOAD_DIR/$file" "$URL/podkop_packets/$file" 2>/dev/null
 done
 opkg install "$DOWNLOAD_DIR"/*.ipk 2>/dev/null
 wget -O "$path_podkop_config" "$URL/config_files/$nameFileReplacePodkop" 2>/dev/null
 echo "Podkop installed.."
fi

printf "\033[32;1mStart and enable service 'doh-proxy'...\033[0m\n"
manage_package "doh-proxy" "enable" "start"

service doh-proxy restart 2>/dev/null
service stubby restart 2>/dev/null
service wdoc restart 2>/dev/null
service wdoc-singbox restart 2>/dev/null
service wdoc-warp restart 2>/dev/null
service wdoc-wg restart 2>/dev/null
service dns-failsafe-proxy restart 2>/dev/null

printf "\033[32;1mService Podkop and Sing-Box restart...\033[0m\n"
service sing-box enable 2>/dev/null
service sing-box restart 2>/dev/null
service podkop enable 2>/dev/null
service podkop restart 2>/dev/null

printf "\033[32;1m$messageComplete...Configured completed...\033[0m\n"
printf "\033[31;1mAfter 10 second AUTOREBOOT ROUTER...\033[0m\n"
sleep 10
reboot