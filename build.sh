#!/bin/bash

set -e

for d in dmd; do
    which $d >/dev/null || (echo "Can't find $d, needed to build"; exit 1)
done

dmd | head -1
echo

set -x

dmd -c -noboundscheck -release source/app.d
gcc app.o -o tinybin -s -m64 -L/usr/lib/x86_64-linux-gnu -Xlinker -l:libphobos2.a -lpthread
