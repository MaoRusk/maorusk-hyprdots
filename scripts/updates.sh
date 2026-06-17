#!/bin/sh
updates=$(checkupdates 2>/dev/null | wc -l)
[ -z "$updates" ] && updates=0
echo "$updates"
