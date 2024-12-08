#!/bin/bash -e

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

trap "echo TRAPed signal" HUP INT QUIT KILL TERM

# Create and modify permissions of XDG_RUNTIME_DIR
sudo -u <user> mkdir -pm700 /tmp/runtime-user
sudo chown <user>:<user> /tmp/runtime-user
sudo -u <user> chmod 700 /tmp/runtime-user
# Make user directory owned by the user in case it is not
sudo chown <user>:<user> /home/<user>
# Change operating system password to environment variable
echo "<user>:$PASSWD" | sudo chpasswd
# Change time zone from environment variable
sudo ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" | sudo tee /etc/timezone > /dev/null
# Add game directories for Lutris and VirtualGL directories to path
export PATH="${PATH}:/usr/local/games:/usr/games:/opt/VirtualGL/bin"

# Start DBus without systemd
sudo /etc/init.d/dbus start

export DISPLAY=":10"
sudo rm -rf /tmp/.X11-unix/X${DISPLAY/:/}
sudo rm -rf /tmp/.X${DISPLAY/:/}-lock

# Run Xvfb server with required extensions
Xvfb "${DISPLAY}" -ac -screen "0" "${SIZEW}x${SIZEH}x${CDEPTH}" -dpi "${DPI}" +extension "RANDR" +extension "GLX" +iglx +extension "MIT-SHM" +render -nolisten "tcp" -noreset -shmem &
sleep 5

# Wait for X11 to start
echo "Waiting for X socket"
if [ -S "/tmp/.X11-unix/X${DISPLAY/:/}" ]; then
  echo "X socket is ready"
else
  exit # retry
fi

if [ "${SSL_ENABLE,,}" = "true" ]; then
  SSL="--ssl-only"
  CERT="--cert $CERT_PATH/server.crt --key $CERT_PATH/server.key"
fi

# Run the x11vnc + noVNC fallback web interface if enabled
if [ -n "$NOVNC_VIEWPASS" ]; then export NOVNC_VIEWONLY="-viewpasswd ${NOVNC_VIEWPASS}"; else unset NOVNC_VIEWONLY; fi
x11vnc -display "${DISPLAY}" -passwd "${BASIC_AUTH_PASSWORD:-$PASSWD}" -shared -forever -repeat -xkb -snapfb -threads -xrandr "resize" -rfbport 5900 ${NOVNC_VIEWONLY} &
/opt/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 8088 --heartbeat 10 $SSL $CERT &

# Use VirtualGL to run the KDE desktop environment with OpenGL if the GPU is available, otherwise use OpenGL with llvmpipe
export FIREFOX_LOG=/tmp/firefox.log
if [ -n "$(nvidia-smi --query-gpu=uuid --format=csv | sed -n 2p)" ]; then
  export VGL_DISPLAY="${VGL_DISPLAY:-egl}"
  export VGL_REFRESHRATE="$REFRESH"
  vglrun +wm firefox --kiosk --width 1920 --height 1080 "localhost" > "$FIREFOX_LOG" 2>&1 &
else
  firefox --kiosk  --width 1920 --height 1080 "localhost" > "$FIREFOX_LOG" 2>&1 &
fi

# Optionally override the default layout with one provided via bind mount
sudo mkdir -p /foxglove
sudo chown <user>:<user> -R /foxglove
sudo chown <user>:<user> -R /app
touch /foxglove/default-layout.json
index_html=$(cat /app/index.html)
replace_pattern='/*FOXGLOVE_STUDIO_DEFAULT_LAYOUT_PLACEHOLDER*/'
replace_value=$(cat /foxglove/default-layout.json)
echo "${index_html/"$replace_pattern"/$replace_value}" > /app/index.html

# Optionally set the extensions manifest via bind mount
if [ -f /app/extensions/manifest.json ]; then
  index_html=$(cat /app/index.html)
  extensions_json=$(cat /app/extensions/manifest.json)
  replace_pattern='/*FOXGLOVE_STUDIO_EXTENSIONS_PLACEHOLDER*/'
  echo "${index_html/"$replace_pattern"/$extensions_json}" > /app/index.html
fi

echo "Session Running. Press [Return] to exit."
read
