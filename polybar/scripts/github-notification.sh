#!/bin/sh

USER="mitander"
TOKEN="$GITHUB_NOTIFICATION_TOKEN"

notifications=$(echo "user = \"$USER:$TOKEN\"" | curl -sf -K- https://api.github.com/notifications | jq ".[].unread" | grep -c true)

if [ "$notifications" -gt 0 ]; then
    echo ""
else
    echo ""
fi
