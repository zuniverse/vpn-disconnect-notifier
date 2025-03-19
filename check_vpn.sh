#!/bin/bash

# Name of VPN interface (often tun0, ppp0 or utunX)
VPN_INTERFACE="tun0"
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
  if ip link show "$VPN_INTERFACE" >/dev/null 2>&1; then
    if [[ "$VPN_STATUS" == "disconnected" || "$VPN_STATUS" == "" ]]; then
      echo "✅ VPN ($VPN_INTERFACE) connected."
      VPN_STATUS="connected"
    fi
  else
    notify "AWS VPN disconnected !"
    # Echo only 1 notification, and optionally open only 1 new terminal window for even more visibility
    if [ "$VPN_STATUS" == "connected" ]; then
      echo "❌ VPN ($VPN_INTERFACE) disconnected !"
      gnome-terminal -- bash -c "echo 'VPN disconnected !'; bash"
      VPN_STATUS="disconnected"
    fi
  fi
  sleep $CHECK_INTERVAL
done
