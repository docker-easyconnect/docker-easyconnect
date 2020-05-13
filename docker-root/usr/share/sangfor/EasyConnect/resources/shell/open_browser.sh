#!/bin/bash
printf '%s\n' "$2" >> /root/open-urls
[ -n "$URLWIN" ] && xmessage "$2" &
