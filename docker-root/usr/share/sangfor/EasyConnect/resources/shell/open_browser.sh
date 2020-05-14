#!/bin/bash
printf '%s\n' "$2" >> /root/open-urls
([ -n "$URLWIN" ] && xmessage -buttons Copy:0,Close:1 "$2" && ( printf %s "$2" | xclip -i -selection clipboard )
)&
