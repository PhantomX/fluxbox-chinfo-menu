#!/bin/bash
# Borrowed from dotnew and adapter.

set -e

xgettext --from-code=utf-8 -L shell -o po/fluxbox-chinfo-menu.pot bin/fluxbox-chinfo-menu
xgettext --from-code=utf-8 -j -L shell -o po/fluxbox-chinfo-menu.pot bin/fluxbox-dm-helper

cd po
for i in *.po; do
	msgmerge -U "${i}" fluxbox-chinfo-menu.pot
done
rm -f ./*~


