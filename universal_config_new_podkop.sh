#!/bin/sh

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
 echo "kmod-amneziawg file downloaded successfully"
 else
 echo "Error downloading kmod-amneziawg. Please, install kmod-amneziawg manually and run the script again"
 exit 1
 fi

 opkg install "$AWG_DIR/$KMOD_AMNEZIAWG_FILENAME"

 if [ $? -eq 0 ]; then
 echo "kmod-amneziawg file downloaded successfully"
 else
 echo "Error installing kmod-amneziawg. Please, install kmod-amneziawg manually and run the script again"
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
 echo "amneziawg-tools file downloaded successfully"
 else
 echo "Error downloading amneziawg-tools. Please, install amneziawg-tools manually and run the script again"
 exit 1
 fi

 opkg install "$AWG_DIR/$AMNEZIAWG_TOOLS_FILENAME"

 if [ $? -eq 0 ]; then
 echo "amneziawg-tools file downloaded successfully"
 else
 echo "Error installing amneziawg-tools. Please, install amneziawg-tools manually and run the script again"
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
 echo "luci-app-amneziawg file downloaded successfully"
 else
 echo "Error downloading luci-app-amneziawg. Please, install luci-app-amneziawg manually and run the script again"
 exit 1
 fi

 opkg install "$AWG_DIR/$LUCI_APP_AMNEZIAWG_FILENAME"

 if [ $? -eq 0 ]; then
 echo "luci-app-amneziawg file downloaded successfully"
 else
 echo "Error installing luci-app-amneziawg. Please, install luci-app-amneziawg manually and run the script again"
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
 if [ "$autostart" = "disable" ]; then
 /etc/init.d/$name disable
 fi
 else
 if [ "$autostart" = "enable" ]; then
 /etc/init.d/$name enable
 fi
 fi

 if pidof $name > /dev/null; then
 if [ "$process" = "stop" ]; then
 /etc/init.d/$name stop
 fi
 else
 if [ "$process" = "start" ]; then
 /etc/init.d/$name start
 fi
 fi
 fi
}

checkPackageAndInstall() {
 local name="$1"
 local isRequired="$2"
 local alt=""

 if [ "$name" = "https-dns-proxy" ]; then
 alt="luci-app-doh-proxy"
 fi

 if [ -n "$alt" ]; then
 if opkg list-installed | grep -qE "^($name|$alt) "; then
 echo "$name or $alt already installed..."
 return 0
 fi
 else
 if opkg list-installed | grep -q "^$name "; then
 echo "$name already installed..."
 return 0
 fi
 fi

 echo "$name not installed. Installing $name..."
 opkg install "$name"
 res=$?

 if [ "$isRequired" = "1" ]; then
 if [ $res -eq 0 ]; then
 echo "$name installed successfully"
 else
 echo "Error installing $name. Please, install $name manually$( [ -n "$alt" ] && echo " or $alt") and run the script again."
 exit 1
 fi
 fi
}

requestConfWARP1()
{
 HASH='68747470733a2f2f73616e74612d61746d6f2e72752f776172702f776172702e706870'
 COMPILE=$(printf '%b' "$(printf '%s\n' "$HASH" | sed 's/../\x&/g')")
 local response=$(curl --connect-timeout 20 --max-time 60 -w "%{http_code}" "$COMPILE" \
 -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36' \
 -H "referer: $COMPILE" \
 -H "Origin: $COMPILE")
 echo "$response"
}

requestConfWARP2()
{
 local result=$(curl --connect-timeout 20 --max-time 60 -w "%{http_code}" 'https://dulcet-fox-556b08.netlify.app/api/warp' \
 -H 'Accept: */*' \
 -H 'Accept-Language: ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7' \
 -H 'Connection: keep-alive' \
 -H 'Content-Type: application/json' \
 -H 'Origin: https://dulcet-fox-556b08.netlify.app/api/warp' \
 -H 'Referer: https://dulcet-fox-556b08.netlify.app/api/warp' \
 -H 'Sec-Fetch-Dest: empty' \
 -H 'Sec-Fetch-Mode: cors' \
 -H 'Sec-Fetch-Site: same-origin' \
 -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36' \
 -H 'sec-ch-ua: "Not(A:Brand";v="99", "Google Chrome";v="133", "Chromium";v="133")' \
 -H 'sec-ch-ua-mobile: ?0' \
 -H 'sec-ch-ua-platform: "Windows"' \
 --data-raw '{"selectedServices":[],"siteMode":"all","deviceType":"computer","endpoint":"162.159.195.1:500"}')
 echo "$result"
}

requestConfWARP3()
{
 local result=$(curl --connect-timeout 20 --max-time 60 -w "%{http_code}" 'https://warp-config-generator-theta.vercel.app/api/warp' \
 -H 'Accept: */*' \
 -H 'Accept-Language: ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7' \
 -H 'Connection: keep-alive' \
 -H 'Content-Type: application/json' \
 -H 'Origin: https://warp-config-generator-theta.vercel.app/api/warp' \
 -H 'Referer: https://warp-config-generator-theta.vercel.app/api/warp' \
 -H 'Sec-Fetch-Dest: empty' \
 -H 'Sec-Fetch-Mode: cors' \
 -H 'Sec-Fetch-Site: same-origin' \
 -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36' \
 -H 'sec-ch-ua: "Not(A:Brand";v="99", "Google Chrome";v="133", "Chromium";v="133")' \
 -H 'sec-ch-ua-mobile: ?0' \
 -H 'sec-ch-ua-platform: "Windows"' \
 --data-raw '{"selectedServices":[],"siteMode":"all","deviceType":"computer","endpoint":"162.159.195.1:500"}')
 echo "$result"
}

requestConfWARP4()
{
 local result=$(curl --connect-timeout 20 --max-time 60 -w "%{http_code}" 'https://generator-warp-config.vercel.app/warp4s?dns=1.1.1.1%2C%201.0.0.1%2C%202606%3A4700%3A4700%3A%3A1111%2C%202606%3A4700%3A4700%3A%3A1001&allowedIPs=0.0.0.0%2F0%2C%20%3A%3A%2F0' \
 -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36' \
 -H 'referer: https://generator-warp-config.vercel.app' \
 -H "Origin: https://generator-warp-config.vercel.app")
 echo "$result"
}

requestConfWARP5()
{
 local result=$(curl --connect-timeout 20 --max-time 60 -w "%{http_code}" 'https://valokda-amnezia.vercel.app/api/warp' \
 -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36' \
 -H 'accept: */*' \
 -H 'accept-language: ru-RU,ru;q=0.9' \
 -H 'referer: https://valokda-amnezia.vercel.app/api/warp')
 echo "$result"
}

requestConfWARP6()
{
 local result=$(curl --connect-timeout 20 --max-time 60 -w "%{http_code}" 'https://warp-gen.vercel.app/generate-config' \
 -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36' \
 -H 'accept: */*' \
 -H 'accept-language: ru-RU,ru;q=0.9' \
 -H 'referer: https://warp-gen.vercel.app/generate-config')
 echo "$result"
}

requestConfWARP7()
{
 local result=$(curl --connect-timeout 20 --max-time 60 -w "%{http_code}" 'https://config-generator-warp.vercel.app/warps' \
 -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36' \
 -H 'accept: */*' \
 -H 'accept-language: ru-RU,ru;q=0.9' \
 -H 'referer: https://config-generator-warp.vercel.app/')
 echo "$result"
}

requestConfWARP8()
{
 local result=$(curl --connect-timeout 20 --max-time 60 -w "%{http_code}" 'https://config-generator-warp.vercel.app/warp6s' \
 -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36' \
 -H 'accept: */*' \
 -H 'accept-language: ru-RU,ru;q=0.9' \
 -H 'referer: https://config-generator-warp.vercel.app/')
 echo "$result"
}

requestConfWARP9()
{
 local result=$(curl --connect-timeout 20 --max-time 60 -w "%{http_code}" 'https://config-generator-warp.vercel.app/warp4s' \
 -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36' \
 -H 'accept: */*' \
 -H 'accept-language: ru-RU,ru;q=0.9' \
 -H 'referer: https://config-generator-warp.vercel.app/')
 echo "$result"
}

requestConfWARP10()
{
 local result=$(curl --connect-timeout 20 --max-time 60 -w "%{http_code}" 'https://warp-generator.vercel.app/api/warp' \
 -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36' \
 -H 'accept: */*' \
 -H 'accept-language: ru-RU,ru;q=0.6' \
 -H 'content-type: application/json' \
 -H 'referer: https://warp-generator.vercel.app/' \
 --data-raw '{"selectedServices":[],"siteMode":"all","deviceType":"computer"}')
 echo "$result"
}

confWarpBuilder()
{
 response_body=$1
 peer_pub=$(echo "$response_body" | jq -r '.result.config.peers[0].public_key')
 client_ipv4=$(echo "$response_body" | jq -r '.result.config.interface.addresses.v4')
 client_ipv6=$(echo "$response_body" | jq -r '.result.config.interface.addresses.v6')
 priv=$(echo "$response_body" | jq -r '.result.key')
 conf=$(cat <<-EOM
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
)
echo "$conf"
}

check_request() {
local response="$1"
local choice="$2"

response_code="${response: -3}"
response_body="${response%???}"
if [ "$response_code" -eq 200 ]; then
case $choice in
1)
warp_config=$(confWarpBuilder "$response_body")
echo "$warp_config"
;;
2)
content=$(echo $response_body | jq -r '.content')
content=$(echo $content | jq -r '.configBase64')
warp_config=$(echo "$content" | base64 -d)
echo "$warp_config"
;;
3)
content=$(echo $response_body | jq -r '.content')
content=$(echo $content | jq -r '.configBase64')
warp_config=$(echo "$content" | base64 -d)
echo "$warp_config"
;;
4)
content=$(echo $response_body | jq -r '.content')
warp_config=$(echo "$content" | base64 -d)
echo "$warp_config"
;;
5)
content=$(echo $response_body | jq -r '.content')
warp_config=$(echo "$content" | base64 -d)
echo "$warp_config"
;;
6)
content=$(echo $response_body | jq -r '.config')
echo "$content"
;;
7)
content=$(echo $response_body | jq -r '.content')
warp_config=$(echo "$content" | base64 -d)
echo "$warp_config"
;;
8)
content=$(echo $response_body | jq -r '.content')
warp_config=$(echo "$content" | base64 -d)
echo "$warp_config"
;;
9)
content=$(echo $response_body | jq -r '.content')
warp_config=$(echo "$content" | base64 -d)
echo "$warp_config"
;;
10)
content=$(echo $response_body | jq -r '.content')
content=$(echo $content | jq -r '.configBase64')
warp_config=$(echo "$content" | base64 -d)
echo "$warp_config"
;;
*)
echo "Error"
esac
else
echo "Error"
fi
}

checkAndAddDomainPermanentName()
{
nameRule="option name '$1'"
str=$(grep -i "$nameRule" /etc/config/dhcp)
if [ -z "$str" ]
then
uci add dhcp domain
uci set dhcp.@domain[-1].name="$1"
uci set dhcp.@domain[-1].ip="$2"
uci commit dhcp
fi
}

byPassGeoBlockXboxDNS()
{
echo "Configure dhcp..."

uci set dhcp.cfg01411c.strictorder='1'
uci set dhcp.cfg01411c.filter_aaaa='1'
uci del dhcp.cfg01411c.server
uci add_list dhcp.cfg01411c.server='127.0.0.1#5359'
uci add_list dhcp.cfg01411c.server='/*.chatgpt.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.oaistatic.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.oaiusercontent.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.openai.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.microsoft.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.windowsupdate.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.bing.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.supercell.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.seeurlpcl.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.supercellid.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.supercellgames.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.clashroyale.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.brawlstars.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.clash.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.clashofclans.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.x.ai/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.grok.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.github.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.forzamotorsport.net/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.forzaracingchampionship.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.forzarc.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.gamepass.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.orithegame.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.renovacionxboxlive.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.tellmewhygame.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.xbox.co/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.xbox.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.xbox.eu/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.xbox.org/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.xbox360.co/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.xbox360.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.xbox360.eu/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.xbox360.org/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.xboxab.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.xboxgamepass.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.xboxgamestudios.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.xboxlive.cn/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.xboxlive.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.xboxone.co/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.xboxone.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.xboxone.eu/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.xboxplayanywhere.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.xboxservices.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.xboxstudios.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.xbx.lv/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.sentry.io/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.usercentrics.eu/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.recaptcha.net/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.gstatic.com/127.0.0.1#5056'
uci add_list dhcp.cfg01411c.server='/*.brawlstarsgame.com/127.0.0.1#5056'
uci commit dhcp

service dnsmasq restart
service odhcpd restart
}

deleteByPassGeoBlockXboxDNS()
{
uci del dhcp.cfg01411c.server
uci add_list dhcp.cfg01411c.server='127.0.0.1#5359'
while uci del dhcp.@domain[-1] ; do : ; done;
uci commit dhcp
service dnsmasq restart
service odhcpd restart
service doh-proxy restart
}

install_youtubeunblock_packages() {
PKGARCH=$(opkg print-architecture | awk 'BEGIN {max=0} {if ($3 > max) {max = $3; arch = $2}} END {print arch}')
VERSION=$(ubus call system board | jsonfilter -e '@.release.version')
BASE_URL="https://github.com/Waujito/youtubeUnblock/releases/download/v1.1.0/"
PACK_NAME="youtubeUnblock"

AWG_DIR="/tmp/$PACK_NAME"
mkdir -p "$AWG_DIR"

if opkg list-installed | grep -q $PACK_NAME; then
echo "$PACK_NAME already installed"
else
PACKAGES="kmod-nfnetlink-queue kmod-nft-queue kmod-nf-conntrack"

for pkg in $PACKAGES; do
if opkg list-installed | grep -q "^$pkg "; then
echo "$pkg already installed"
else
echo "$pkg not installed. Instal..."
opkg install $pkg
if [ $? -eq 0 ]; then
echo "$pkg file installing successfully"
else
echo "Error installing $pkg Please, install $pkg manually and run the script again"
exit 1
fi
fi
done

YOUTUBEUNBLOCK_FILENAME="youtubeUnblock-1.1.0-2-2d579d5-${PKGARCH}-openwrt-23.05.ipk"
DOWNLOAD_URL="${BASE_URL}${YOUTUBEUNBLOCK_FILENAME}"
echo $DOWNLOAD_URL
wget -O "$AWG_DIR/$YOUTUBEUNBLOCK_FILENAME" "$DOWNLOAD_URL"

if [ $? -eq 0 ]; then
echo "$PACK_NAME file downloaded successfully"
else
echo "Error downloading $PACK_NAME. Please, install $PACK_NAME manually and run the script again"
exit 1
fi

opkg install "$AWG_DIR/$YOUTUBEUNBLOCK_FILENAME"

if [ $? -eq 0 ]; then
echo "$PACK_NAME file installing successfully"
else
echo "Error installing $PACK_NAME. Please, install $PACK_NAME manually and run the script again"
exit 1
fi
fi

PACK_NAME="luci-app-youtubeUnblock"
if opkg list-installed | grep -q $PACK_NAME; then
echo "$PACK_NAME already installed"
else
PACK_NAME="luci-app-youtubeUnblock"
YOUTUBEUNBLOCK_FILENAME="luci-app-youtubeUnblock-1.1.0-1-473af29.ipk"
DOWNLOAD_URL="${BASE_URL}${YOUTUBEUNBLOCK_FILENAME}"
echo $DOWNLOAD_URL
wget -O "$AWG_DIR/$YOUTUBEUNBLOCK_FILENAME" "$DOWNLOAD_URL"

if [ $? -eq 0 ]; then
echo "$PACK_NAME file downloaded successfully"
else
echo "Error downloading $PACK_NAME. Please, install $PACK_NAME manually and run the script again"
exit 1
fi

opkg install "$AWG_DIR/$YOUTUBEUNBLOCK_FILENAME"

if [ $? -eq 0 ]; then
echo "$PACK_NAME file installing successfully"
else
echo "Error installing $PACK_NAME. Please, install $PACK_NAME manually and run the script again"
exit 1
fi
fi

rm -rf "$AWG_DIR"
}

if [ "$1" = "y" ] || [ "$1" = "Y" ]
then
is_manual_input_parameters="y"
else
is_manual_input_parameters="n"
fi
if [ "$2" = "y" ] || [ "$2" = "Y" ] || [ "$2" = "" ]
then
is_reconfig_podkop="y"
else
is_reconfig_podkop="n"
fi

echo "Update list packages..."
opkg update

checkPackageAndInstall "coreutils-base64" "1"

cp -f "$DIR/$file" "$DIR_BACKUP/$file"
done
echo "Replace configs..."

for file in $config_files
do
if [ "$file" == "https-dns-proxy" ]
then
wget -O "$DIR/$file" "$URL/config_files/$file"
fi
done
fi

echo "Configure dhcp..."

uci set dhcp.cfg01411c.strictorder='1'
uci set dhcp.cfg01411c.filter_aaaa='1'
uci commit dhcp

cat << EOF > /etc/sing-box/config.json
{
"log": {
"disabled": true,
"level": "error"
},
"inbounds": [
{
"type": "tproxy",
"listen": "::",
"listen_port": 1100,
"sniff": false
}
],
"outbounds": [
{
"type": "http",
"server": "127.0.0.1",
"server_port": 18080
}
],
"route": {
"auto_detect_interface": true
}
}
EOF

echo "Setting sing-box..."
uci set sing-box.main.enabled='1'
uci set sing-box.main.user='root'
uci add_list sing-box.main.ifaces='wan'
uci add_list sing-box.main.ifaces='wan2'
uci add_list sing-box.main.ifaces='wan6'
uci add_list sing-box.main.ifaces='wwan'
uci add_list sing-box.main.ifaces='wwan0'
uci add_list sing-box.main.ifaces='modem'
uci add_list sing-box.main.ifaces='l2tp'
uci add_list sing-box.main.ifaces='pptp'
uci commit sing-box

nameRule="option name 'Block_UDP_443'"
str=$(grep -i "$nameRule" /etc/config/firewall)
if [ -z "$str" ]
then
echo "Add block QUIC..."

uci add firewall rule
uci set firewall.@rule[-1].name='Block_UDP_80'
uci add_list firewall.@rule[-1].proto='udp'
uci set firewall.@rule[-1].src='lan'
uci set firewall.@rule[-1].dest='wan'
uci set firewall.@rule[-1].dest_port='80'
uci set firewall.@rule[-1].target='REJECT'
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
opkg upgrade youtubeUnblock
opkg upgrade luci-app-youtubeUnblock
manage_package "youtubeUnblock" "enable" "start"
wget -O "/etc/config/youtubeUnblock" "$URL/config_files/youtubeUnblockSecond"
manage_package "podkop" "enable" "stop"
service youtubeUnblock restart

isWorkYoutubeUnBlock=0

curl -f -o /dev/null -k --connect-to ::google.com -L -H "Host: mirror.gcr.io" --max-time 360 https://test.googlevideo.com/v2/cimg/android/blobs/sha256:6fd8bdac3da660bde7bd0b6f2b6a46e1b686afb74b9a4614def32532b73f5eaa

if [ $? -eq 0 ]; then
printf "\033[32;1myoutubeUnblock well work...\033[0m\n"
cronTask="0 4 * * * service youtubeUnblock restart"
str=$(grep -i "0 4 * * * service youtubeUnblock restart" /etc/crontabs/root)
if [ -z "$str" ]
then
echo "Add cron task auto reboot service youtubeUnblock..."
echo "$cronTask" >> /etc/crontabs/root
fi
isWorkYoutubeUnBlock=1
else
manage_package "youtubeUnblock" "disable" "stop"
printf "\033[32;1myoutubeUnblock not work...\033[0m\n"
isWorkYoutubeUnBlock=0
str=$(grep -i "0 4 * * * service youtubeUnblock restart" /etc/crontabs/root)
if [ ! -z "$str" ]
then
grep -v "0 4 * * * service youtubeUnblock restart" /etc/crontabs/root > /etc/crontabs/temp
cp -f "/etc/crontabs/temp" "/etc/crontabs/root"
rm -f "/etc/crontabs/temp"
fi
fi

isWorkOperaProxy=0
printf "\033[32;1mCheck opera proxy...\033[0m\n"
service sing-box restart
curl --proxy http://127.0.0.1:18080 ipinfo.io/ip
if [ $? -eq 0 ]; then
printf "\033[32;1mOpera proxy well work...\033[0m\n"
isWorkOperaProxy=1
else
printf "\033[32;1mOpera proxy not work...\033[0m\n"
isWorkOperaProxy=0
fi

countRepeatAWGGen=2
currIter=0
isExit=0
while [ $currIter -lt $countRepeatAWGGen ] && [ "$isExit" = "0" ]
do
currIter=$(( $currIter + 1 ))
printf "\033[32;1mCreate and Check AWG WARP... Attempt #$currIter... Please wait...\033[0m\n"
if [ "$is_manual_input_parameters" = "y" ] || [ "$is_manual_input_parameters" = "Y" ]
then
read -r -p "Enter the private key (from [Interface]):"$'\n' PrivateKey
read -r -p "Enter S1 value (from [Interface]):"$'\n' S1
read -r -p "Enter S2 value (from [Interface]):"$'\n' S2
read -r -p "Enter Jc value (from [Interface]):"$'\n' Jc
read -r -p "Enter Jmin value (from [Interface]):"$'\n' Jmin
read -r -p "Enter Jmax value (from [Interface]):"$'\n' Jmax
read -r -p "Enter H1 value (from [Interface]):"$'\n' H1
read -r -p "Enter H2 value (from [Interface]):"$'\n' H2
read -r -p "Enter H3 value (from [Interface]):"$'\n' H3
read -r -p "Enter H4 value (from [Interface]):"$'\n' H4

while true; do
read -r -p "Enter internal IP address with subnet, example 192.168.100.5/24 (from [Interface]):"$'\n' Address
if echo "$Address" | egrep -oq '^([0-9]{1,3}.){3}[0-9]{1,3}(\/[0-9]+)?$'; then
break
else
echo "This IP is not valid. Please repeat"
fi
done

read -r -p "Enter the public key (from [Peer]):"$'\n' PublicKey
read -r -p "Enter Endpoint host without port (Domain or IP) (from [Peer]):"$'\n' EndpointIP
read -r -p "Enter Endpoint host port (from [Peer]) [51820]:"$'\n' EndpointPort

DNS="1.1.1.1"
MTU=1280
AllowedIPs="0.0.0.0/0"
isExit=1
else
warp_config="Error"
printf "\033[32;1mRequest WARP config... Attempt #1\033[0m\n"
result=$(requestConfWARP1)
warpGen=$(check_request "$result" 1)
if [ "$warpGen" = "Error" ]
then
printf "\033[32;1mRequest WARP config... Attempt #2\033[0m\n"
result=$(requestConfWARP2)
warpGen=$(check_request "$result" 2)
if [ "$warpGen" = "Error" ]
then
printf "\033[32;1mRequest WARP config... Attempt #3\033[0m\n"
result=$(requestConfWARP3)
warpGen=$(check_request "$result" 3)
if [ "$warpGen" = "Error" ]
then
printf "\033[32;1mRequest WARP config... Attempt #4\033[0m\n"
result=$(requestConfWARP4)
warpGen=$(check_request "$result" 4)
if [ "$warpGen" = "Error" ]
then
printf "\033[32;1mRequest WARP config... Attempt #5\033[0m\n"
result=$(requestConfWARP5)
warpGen=$(check_request "$result" 5)
if [ "$warpGen" = "Error" ]
then
printf "\033[32;1mRequest WARP config... Attempt #6\033[0m\n"
result=$(requestConfWARP6)
warpGen=$(check_request "$result" 6)
if [ "$warpGen" = "Error" ]
then
printf "\033[32;1mRequest WARP config... Attempt #7\033[0m\n"
result=$(requestConfWARP7)
warpGen=$(check_request "$result" 7)
if [ "$warpGen" = "Error" ]
then
printf "\033[32;1mRequest WARP config... Attempt #8\033[0m\n"
result=$(requestConfWARP8)
warpGen=$(check_request "$result" 8)
if [ "$warpGen" = "Error" ]
then
printf "\033[32;1mRequest WARP config... Attempt #9\033[0m\n"
result=$(requestConfWARP9)
warpGen=$(check_request "$result" 9)
if [ "$warpGen" = "Error" ]
then
printf "\033[32;1mRequest WARP config... Attempt #10\033[0m\n"
result=$(requestConfWARP10)
warpGen=$(check_request "$result" 10)
if [ "$warpGen" = "Error" ]
then
warp_config="Error"
else
warp_config=$warpGen
fi
else
warp_config=$warpGen
fi
else
warp_config=$warpGen
fi
else
warp_config=$warpGen
fi
else
warp_config=$warpGen
fi
else
warp_config=$warpGen
fi
else
warp_config=$warpGen
fi
else
warp_config=$warpGen
fi
else
warp_config=$warpGen
fi
else
warp_config=$warpGen
fi

if [ "$warp_config" = "Error" ]
then
printf "\033[32;1mGenerate config AWG WARP failed...Try again later...\033[0m\n"
isExit=2
else
while IFS=' = ' read -r line; do
if echo "$line" | grep -q "="; then
key=$(echo "$line" | cut -d'=' -f1 | xargs)
value=$(echo "$line" | cut -d'=' -f2- | xargs)
eval "$key=$value"
fi
done < <(echo "$warp_config")

Address=$(echo "$Address" | cut -d',' -f1)
DNS=$(echo "$DNS" | cut -d',' -f1)
AllowedIPs=$(echo "$AllowedIPs" | cut -d',' -f1)
EndpointIP=$(echo "$Endpoint" | cut -d':' -f1)
EndpointPort=$(echo "$Endpoint" | cut -d':' -f2)
fi
fi

if [ "$isExit" = "2" ]
then
isExit=0
else
printf "\033[32;1mCreate and configure tunnel AmneziaWG WARP...\033[0m\n"

INTERFACE_NAME="awg10"
CONFIG_NAME="amneziawg_awg10"
PROTO="amneziawg"
ZONE_NAME="awg"

uci set network.${INTERFACE_NAME}=interface
uci set network.${INTERFACE_NAME}.proto=$PROTO
if ! uci show network | grep -q ${CONFIG_NAME}; then
uci add network ${CONFIG_NAME}
fi
uci set network.${INTERFACE_NAME}.private_key=$PrivateKey
uci del network.${INTERFACE_NAME}.addresses
uci add_list network.${INTERFACE_NAME}.addresses=$Address
uci set network.${INTERFACE_NAME}.mtu=$MTU
uci set network.${INTERFACE_NAME}.awg_jc=$Jc
uci set network.${INTERFACE_NAME}.awg_jmin=$Jmin
uci set network.${INTERFACE_NAME}.awg_jmax=$Jmax
uci set network.${INTERFACE_NAME}.awg_s1=$S1
uci set network.${INTERFACE_NAME}.awg_s2=$S2
uci set network.${INTERFACE_NAME}.awg_h1=$H1
uci set network.${INTERFACE_NAME}.awg_h2=$H2
uci set network.${INTERFACE_NAME}.awg_h3=$H3
uci set network.${INTERFACE_NAME}.awg_h4=$H4
uci set network.${INTERFACE_NAME}.nohostroute='1'

uci set network.@${CONFIG_NAME}[-1].description="${INTERFACE_NAME}_peer"
uci set network.@${CONFIG_NAME}[-1].public_key=$PublicKey
uci set network.@${CONFIG_NAME}[-1].endpoint_host=$EndpointIP
uci set network.@${CONFIG_NAME}[-1].endpoint_port=$EndpointPort
uci set network.@${CONFIG_NAME}[-1].persistent_keepalive='25'
uci set network.@${CONFIG_NAME}[-1].allowed_ips='0.0.0.0/0'
uci set network.@${CONFIG_NAME}[-1].route_allowed_ips='0'
uci commit network

if ! uci show firewall | grep -q "@zone.*name='${ZONE_NAME}'"; then
printf "\033[32;1mZone Create\033[0m\n"
uci add firewall zone
uci set firewall.@zone[-1].name=$ZONE_NAME
uci set firewall.@zone[-1].network=$INTERFACE_NAME
uci set firewall.@zone[-1].forward='REJECT'
uci set firewall.@zone[-1].output='ACCEPT'
uci set firewall.@zone[-1].input='REJECT'
uci set firewall.@zone[-1].masq='1'
uci set firewall.@zone[-1].mtu_fix='1'
uci set firewall.@zone[-1].family='ipv4'
uci commit firewall
fi

if ! uci show firewall | grep -q "@forwarding.*name='${ZONE_NAME}'"; then
printf "\033[32;1mConfigured forwarding\033[0m\n"
uci add firewall forwarding
uci set firewall.@forwarding[-1]=forwarding
uci set firewall.@forwarding[-1].name="${ZONE_NAME}"
uci set firewall.@forwarding[-1].dest=${ZONE_NAME}
uci set firewall.@forwarding[-1].src='lan'
uci set firewall.@forwarding[-1].family='ipv4'
uci commit firewall
fi

ZONES=$(uci show firewall | grep "zone$" | cut -d'=' -f1)
for zone in $ZONES; do
CURR_ZONE_NAME=$(uci get $zone.name)
if [ "$CURR_ZONE_NAME" = "$ZONE_NAME" ]; then
if ! uci get $zone.network | grep -q "$INTERFACE_NAME"; then
uci add_list $zone.network="$INTERFACE_NAME"
uci commit firewall
fi
fi
done
if [ "$currIter" = "1" ]
then
service firewall restart
fi

if [ "$is_manual_input_parameters" = "n" ]; then
I=0
WARP_ENDPOINT_HOSTS="engage.cloudflareclient.com 162.159.192.1 162.159.192.2 162.159.192.4 162.159.195.1 162.159.195.4 188.114.96.1 188.114.96.23 188.114.96.50 188.114.96.81"
WARP_ENDPOINT_PORTS="500"
for element in $WARP_ENDPOINT_HOSTS; do
EndpointIP="$element"
for element2 in $WARP_ENDPOINT_PORTS; do
I=$(( $I + 1 ))
EndpointPort="$element2"
uci set network.@${CONFIG_NAME}[-1].endpoint_host=$EndpointIP
uci set network.@${CONFIG_NAME}[-1].endpoint_port=$EndpointPort
uci commit network
ifdown $INTERFACE_NAME
ifup $INTERFACE_NAME
printf "\033[33;1mIter #$I: Check Endpoint WARP $element:$element2. Wait up AWG WARP 10 second...\033[0m\n"
sleep 10

pingAddress="8.8.8.8"
if ping -c 1 -I $INTERFACE_NAME $pingAddress >/dev/null 2>&1
then
printf "\033[32;1m Endpoint WARP $element:$element2 work...\033[0m\n"
isExit=1
break
else
printf "\033[31;1m Endpoint WARP $element:$element2 not work...\033[0m\n"
isExit=0
fi
done
if [ "$isExit" = "1" ]
then
break
fi
done
else
ifdown $INTERFACE_NAME
ifup $INTERFACE_NAME
printf "\033[32;1mWait up AWG WARP 10 second...\033[0m\n"
sleep 10

pingAddress="8.8.8.8"
if ping -c 1 -I $INTERFACE_NAME $pingAddress >/dev/null 2>&1
then
isExit=1
else
isExit=0
fi
fi
fi
done

varByPass=0
isWorkWARP=0

if [ "$isExit" = "1" ]
then
printf "\033[32;1mAWG WARP well work...\033[0m\n"
isWorkWARP=1
else
printf "\033[32;1mAWG WARP not work.....Try opera proxy...\033[0m\n"
isWorkWARP=0
fi

echo "isWorkYoutubeUnBlock = $isWorkYoutubeUnBlock, isWorkOperaProxy = $isWorkOperaProxy, isWorkWARP = $isWorkWARP"

if [ "$isWorkYoutubeUnBlock" = "1" ] && [ "$isWorkOperaProxy" = "1" ] && [ "$isWorkWARP" = "1" ]
then
varByPass=1
elif [ "$isWorkYoutubeUnBlock" = "0" ] && [ "$isWorkOperaProxy" = "1" ] && [ "$isWorkWARP" = "1" ]
then
varByPass=2
elif [ "$isWorkYoutubeUnBlock" = "1" ] && [ "$isWorkOperaProxy" = "1" ] && [ "$isWorkWARP" = "0" ]
then
varByPass=3
elif [ "$isWorkYoutubeUnBlock" = "0" ] && [ "$isWorkOperaProxy" = "1" ] && [ "$isWorkWARP" = "0" ]
then
varByPass=4
elif [ "$isWorkYoutubeUnBlock" = "1" ] && [ "$isWorkOperaProxy" = "0" ] && [ "$isWorkWARP" = "0" ]
then
varByPass=5
elif [ "$isWorkYoutubeUnBlock" = "0" ] && [ "$isWorkOperaProxy" = "0" ] && [ "$isWorkWARP" = "1" ]
then
varByPass=6
elif [ "$isWorkYoutubeUnBlock" = "1" ] && [ "$isWorkOperaProxy" = "0" ] && [ "$isWorkWARP" = "1" ]
then
varByPass=7
elif [ "$isWorkYoutubeUnBlock" = "0" ] && [ "$isWorkOperaProxy" = "0" ] && [ "$isWorkWARP" = "0" ]
then
varByPass=8
fi

printf "\033[32;1mRestart service dnsmasq, odhcpd...\033[0m\n"
service dnsmasq restart
service odhcpd restart

path_podkop_config="/etc/config/podkop"
path_podkop_config_backup="/root/podkop"
URL="https://raw.githubusercontent.com/gangstap/283r2jhr3h28o/refs/heads/main"

messageComplete=""

case $varByPass in
1)
nameFileReplacePodkop="podkopNewNoYoutube"
printf "\033[32;1mStop and disabled service 'ruantiblock' and 'youtubeUnblock' and 'zapret'...\033[0m\n"
manage_package "ruantiblock" "disable" "stop"
manage_package "youtubeUnblock" "disable" "stop"
manage_package "zapret" "disable" "stop"
service zapret2 restart
deleteByPassGeoBlockXboxDNS
messageComplete="ByPass block for Method 1: AWG WARP + zapret2 + Opera Proxy...Configured completed..."
;;
2)
nameFileReplacePodkop="podkopNew"
printf "\033[32;1mStop and disabled service 'youtubeUnblock' and 'ruantiblock' and 'zapret' and 'zapret2'...\033[0m\n"
manage_package "youtubeUnblock" "disable" "stop"
manage_package "ruantiblock" "disable" "stop"
manage_package "zapret" "disable" "stop"
manage_package "zapret2" "disable" "stop"
deleteByPassGeoBlockXboxDNS
messageComplete="ByPass block for Method 2: AWG WARP + Opera Proxy...Configured completed..."
;;
3)
nameFileReplacePodkop="podkopNewSecond"
printf "\033[32;1mStop and disabled service 'ruantiblock' and 'youtubeUnblock' and 'zapret' ...\033[0m\n"
manage_package "ruantiblock" "disable" "stop"
manage_package "youtubeUnblock" "disable" "stop"
manage_package "zapret" "disable" "stop"
service zapret2 restart
deleteByPassGeoBlockXboxDNS
messageComplete="ByPass block for Method 3: zapret2 + Opera Proxy...Configured completed..."
;;
4)
nameFileReplacePodkop="podkopNewSecondYoutube"
printf "\033[32;1mStop and disabled service 'youtubeUnblock' and 'ruantiblock' and 'zapret' and 'zapret2'...\033[0m\n"
manage_package "youtubeUnblock" "disable" "stop"
manage_package "ruantiblock" "disable" "stop"
manage_package "zapret" "disable" "stop"
manage_package "zapret2" "disable" "stop"
deleteByPassGeoBlockXboxDNS
messageComplete="ByPass block for Method 4: Only Opera Proxy...Configured completed..."
;;
5)
nameFileReplacePodkop="podkopNewSecondYoutube"
printf "\033[32;1mStop and disabled service 'ruantiblock' and 'podkop' and 'youtubeunblock' and 'zapret'...\033[0m\n"
manage_package "ruantiblock" "disable" "stop"
manage_package "podkop" "disable" "stop"
manage_package "youtubeunblock" "disable" "stop"
manage_package "zapret" "disable" "stop"
wget -O "/opt/zapret2/ipset/zapret_hosts_user.txt" "$URL/config_files/zapret-hosts-user-second.txt"
service zapret2 restart
byPassGeoBlockXboxDNS
printf "\033[32;1mByPass block for Method 5: zapret2 + XboxDNS for GeoBlock...Configured completed...\033[0m\n"
exit 1
;;
6)
nameFileReplacePodkop="podkopNewWARP"
printf "\033[32;1mStop and disabled service 'youtubeUnblock' and 'ruantiblock' and 'zapret' and 'zapret2'...\033[0m\n"
manage_package "youtubeUnblock" "disable" "stop"
manage_package "ruantiblock" "disable" "stop"
manage_package "zapret" "disable" "stop"
manage_package "zapret2" "disable" "stop"
byPassGeoBlockXboxDNS
messageComplete="ByPass block for Method 6: AWG WARP + XboxDNS for GeoBlock...Configured completed..."
;;
7)
nameFileReplacePodkop="podkopNewWARPNoYoutube"
printf "\033[32;1mStop and disabled service 'ruantiblock' and 'youtubeUnblock' and 'zapret'...\033[0m\n"
manage_package "ruantiblock" "disable" "stop"
manage_package "youtubeUnblock" "disable" "stop"
manage_package "zapret" "disable" "stop"
service zapret2 restart
byPassGeoBlockXboxDNS
messageComplete="ByPass block for Method 7: AWG WARP + zapret2 + XboxDNS for GeoBlock...Configured completed..."
;;
8)
printf "\033[32;1mTry custom settings router to bypass the locks... Recomendation buy 'VPS' and up 'vless'\033[0m\n"
exit 1
;;
*)
echo "Unknown error. Please send message to your support group."
exit 1
esac

PACKAGE="podkop"
REQUIRED_VERSION="v0.7.21-r1"

INSTALLED_VERSION=$(opkg list-installed | grep "^$PACKAGE" | cut -d ' ' -f 3)
if [ -n "$INSTALLED_VERSION" ] && [ "$INSTALLED_VERSION" != "$REQUIRED_VERSION" ]; then
echo "Version package $PACKAGE not equal $REQUIRED_VERSION. Removed packages..."
opkg remove --force-removal-of-dependent-packages $PACKAGE
fi

if [ -f "/etc/init.d/podkop" ]; then
if [ "$is_reconfig_podkop" = "y" ] || [ "$is_reconfig_podkop" = "Y" ]; then
cp -f "$path_podkop_config" "$path_podkop_config_backup"
wget -O "$path_podkop_config" "$URL/config_files/$nameFileReplacePodkop"
echo "Backup of your config in path '$path_podkop_config_backup'"
echo "Podkop reconfigured..."
fi
else
is_install_podkop="y"

if [ "$is_install_podkop" = "y" ] || [ "$is_install_podkop" = "Y" ]; then
DOWNLOAD_DIR="/tmp/podkop"
mkdir -p "$DOWNLOAD_DIR"
podkop_files="podkop-v0.7.21-r1-all.ipk
luci-app-podkop-v0.7.21-r1-all.ipk
luci-i18n-podkop-ru-0.7.21.ipk"
for file in $podkop_files
do
echo "Download $file..."
wget -q -O "$DOWNLOAD_DIR/$file" "$URL/podkop_packets/$file"
done
opkg install $DOWNLOAD_DIR/podkop*.ipk
opkg install $DOWNLOAD_DIR/luci-app-podkop*.ipk
opkg install $DOWNLOAD_DIR/luci-i18n-podkop-ru*.ipk
rm -f $DOWNLOAD_DIR/podkop*.ipk $DOWNLOAD_DIR/luci-app-podkop*.ipk $DOWNLOAD_DIR/luci-i18n-podkop-ru*.ipk
wget -O "$path_podkop_config" "$URL/config_files/$nameFileReplacePodkop"
echo "Podkop installed.."
fi
fi

printf "\033[32;1mStart and enable service 'doh-proxy'...\033[0m\n"
manage_package "doh-proxy" "enable" "start"

str=$(grep -i "0 4 * * * wget -O - $URL/configure_zaprets.sh | sh" /etc/crontabs/root)
if [ ! -z "$str" ]
then
grep -v "0 4 * * * wget -O - $URL/configure_zaprets.sh | sh" /etc/crontabs/root > /etc/crontabs/temp
cp -f "/etc/crontabs/temp" "/etc/crontabs/root"
rm -f "/etc/crontabs/temp"
fi

service doh-proxy restart
service stubby restart
service wdoc restart
service wdoc-singbox restart
service wdoc-warp restart
service wdoc-wg restart
service dns-failsafe-proxy restart

printf "\033[32;1mService Podkop and Sing-Box restart...\033[0m\n"
service sing-box enable
service sing-box restart
service podkop enable
service podkop restart

printf "\033[32;1m$messageComplete\033[0m\n"
printf "\033[31;1mAfter 10 second AUTOREBOOT ROUTER...\033[0m\n"
sleep 10
reboot