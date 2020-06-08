#!/bin/sh

doas xbps-install --sync > /dev/null 2>&1
num=$(xbps-install --update --dry-run | wc -l)
[ -n "$num" ] && [ "$num" -gt 0 ] && echo " $num"
