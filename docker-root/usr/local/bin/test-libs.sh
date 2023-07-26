#!/bin/sh
ret=0
for exe in "$@"; do
	if output="$(ldd "$exe" 2>/dev/null | grep "=> not found")"; then
		echo "$exe"
		echo "$output"
		ret=1
	fi
done
return $ret
