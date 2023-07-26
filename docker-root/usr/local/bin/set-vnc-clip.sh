#!/bin/sh
printf %s "$1" | DISPLAY=:1 xclip -selection clipboard
