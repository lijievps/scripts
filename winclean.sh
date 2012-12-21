#!/bin/bash

# Windows Cleanup 2012.12.20
# Copyright (c) 2012 Renato Silva
# GNU GPLv2 licensed

# Run only on shutdown or --force
shutdown_happening=$(wevtutil qe system //c:1 //rd:true //f:xml //q:"*[System[(EventID=1074) and TimeCreated[timediff(@SystemTime) <= 60000]]]")
[[ -z "$shutdown_happening" && "$1" != "--force" ]] && exit

# Run backup on shutdown, wait for phone sync if not rebooting
non_reboot_shutdown=$(echo "$shutdown_happening" | grep -i "<data>desligado</data>")
[[ -n "$non_reboot_shutdown" ]] && delay=120
[[ -n "$shutdown_happening" ]] && mintty -w full bash backup --default "$delay"

# Firefox bookmarks cleanup: remove unorganized and descriptions
database=("$APPDATA/Mozilla/Firefox/profiles/"*"/places.sqlite")
sqlite "$database" "delete from moz_bookmarks where parent = (select folder_id from moz_bookmarks_roots where root_name = 'unfiled')"
sqlite "$database" "delete from moz_items_annos where id in (select i.id from moz_bookmarks b, moz_items_annos i where b.id = i.item_id and b.type = 1
    and title != '' and title not in ('Favoritos do dispositivo m�vel', 'Favoritos recentes', 'Mais visitados', 'Tags recentes', 'Hist�rico', 'Downloads', 'Tags'))"

# Cleanup recent files list from Word Viewer
filename="$TEMP/winclean.$(date +%s.%N).reg"
trap "rm -r $filename" EXIT
echo 'Windows Registry Editor Version 5.00
[HKEY_CURRENT_USER\Software\Microsoft\Office\11.0\Wordview\Data]
"Settings"=-' > "$filename"
regedit //s "$filename"

# Cleanup WMP junk
reg_data=$(reg query 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders' //v 'My Music')
music=$(echo "$reg_data" | awk -F'REG_SZ[[:space:]]*' 'NF>1{print $2}')
[[ -d "$music" ]] && find "$music" -iname "*.jpg" -delete

# Let CCleaner do its job
reg_data=$(reg query 'HKEY_LOCAL_MACHINE\SOFTWARE\Piriform\CCleaner' //ve)
ccleaner_dir=$(echo "$reg_data" | awk -F'REG_SZ[[:space:]]*' 'NF>1{print $2}')
"$ccleaner_dir/ccleaner.exe" //auto