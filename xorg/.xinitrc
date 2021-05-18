# Set dpi
xrandr; xrdb "${HOME}"/.Xresources

# Enable pixel-perfect scrolling in firefox
export MOZ_USE_XINPUT2=1

# Start bspwm
#exec bspwm
exec dbus-launch --autolaunch=$(cat /var/lib/dbus/machine-id) bspwm
