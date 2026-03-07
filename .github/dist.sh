#!/bin/bash

set -euo pipefail
IFS=$'\t\n'

if [[ -d dist ]]; then
	rm -r dist
fi
mkdir dist
cp -r r4 modulepack.plot.conf dist/
cd dist
git submodule update --init
luajit ../TPT-Script-Manager/modulepack.lua modulepack.plot.conf:../spaghetti/modulepack.plot.conf > r4plot.lua
