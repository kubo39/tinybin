#!/bin/bash

set -e

for d in dmd git dub strip; do
    which $d >/dev/null || (echo "Can't find $d, needed to build"; exit 1)
done

dmd | head -1
echo

if [ ! -d syscall.d ]; then
    git clone git://github.com/kubo39/syscall.d
    dub add-local syscall.d ~master
    echo
fi

set -x

dub build --build=release

strip tinybin
