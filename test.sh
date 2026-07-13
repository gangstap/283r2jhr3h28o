# 1. Делаем резервную копию
cp /etc/board.json /etc/board.json.bak

# 2. Подменяем имя модели на Routerich
sed -i 's/"model": {/"model": {"name": "Routerich AX3000",/g' /etc/board.json
# Или более безопасный вариант, меняем только board_name:
sed -i 's/"board_name": ".*"/"board_name": "routerich-ax3000"/g' /etc/board.json

# 3. Перезапускаем ubus, чтобы изменения вступили в силу (или просто перезагрузи роутер)
killall -HUP ubusd