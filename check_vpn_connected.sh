#!/bin/bash

#########################################################################
# Simple bash script that checks every x seconds if VPN is connected.
# If VPN is disconnected, it sends a notification on the user's screen.
# And optionnally opens a new terminal window for even more visibility.
#########################################################################

# Name of VPN interface (often tun0, ppp0 or utunX)
# VPN Type	 Interface examples
# OpenVPN	   tun0, tun1, etc.
# WireGuard	 wg0, wg1
# L2TP/IPSec ppp0
# macOS VPN	 utun0, utun1
VPN_INTERFACE="tun|ppp|wg|utun"
CHECK_INTERVAL=30 #seconds
VPN_STATUS=""

# Notify on Linux with notify-send and macOS with terminal-notifier
function notify() {
  MESSAGE=$1
  if command -v notify-send >/dev/null 2>&1; then
    # For Linux with libnotify
    notify-send -t 10000 "VPN Status" "$MESSAGE"
  elif command -v terminal-notifier >/dev/null 2>&1; then
    # For macOS with terminal-notifier
    terminal-notifier -title "VPN Status" -message "$MESSAGE"
  else
    # Simple message
    echo "$MESSAGE"
  fi
}

while true; do
  # Check if VPN interface exists
  if ip link | grep -E "$VPN_INTERFACE" >/dev/null 2>&1; then
    if [[ "$VPN_STATUS" == "disconnected" || "$VPN_STATUS" == "" ]]; then
      echo "✅ VPN ($VPN_INTERFACE) connected."
      VPN_STATUS="connected"
    fi
  else
    # Check that session is not locked to avoid sending notifications that will wake up screen saver
    # the following command will return either (false,) or (true,)
    IS_SESSION_LOCKED=$(gdbus call --session \
      --dest org.gnome.ScreenSaver \
      --object-path /org/gnome/ScreenSaver \
      --method org.gnome.ScreenSaver.GetActive)
    if [[ "$IS_SESSION_LOCKED" == "(false,)" ]]; then
      notify "AWS VPN disconnected !"
    fi
    # Echo only 1 notification, and optionally open only 1 new terminal window for even more visibility
    if [ "$VPN_STATUS" != "disconnected" ]; then
      echo "❌ VPN ($VPN_INTERFACE) disconnected !"
      # gnome-terminal -- bash -c "echo 'VPN disconnected !'; bash" # open a new terminal window for even more visibility
      VPN_STATUS="disconnected"
    fi
  fi
  sleep $CHECK_INTERVAL
done
