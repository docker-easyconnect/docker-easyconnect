#!/bin/sh
exec find /usr/share/sangfor/ -executable -type f -exec test-libs.sh \{\} +
