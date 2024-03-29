#!/usr/bin/env sh

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch bar
polybar -c $HOME/.config/polybar/config.ini main &

#external_monitor=$(xrandr --query | grep 'HDMI-1')

#if [ $external_monitor = *connected* ]; then
polybar -c $HOME/.config/polybar/config.ini external &
#fi
