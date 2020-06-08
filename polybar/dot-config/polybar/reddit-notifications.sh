#!/bin/sh

notifications=$(curl -sf --user-agent "$REDDIT_NOTIFICATION_USERAGENT" "$REDDIT_NOTIFICATION_URL" | jq '.["data"]["children"] | length')
[ -n "$notifications" ] && [ "$notifications" -gt 0 ] && echo " $notifications"
