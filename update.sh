#!/bin/bash
REPO='savente93/spec-zero-tools'
gh release download -R "$REPO" --pattern schedule.json --clobber
for line in $(jq 'map(select(.start_date |fromdateiso8601 |tonumber  < now))| sort_by("start_date") | reverse | .[0].packages | to_entries | map(.key + ":" + .value)[]' --raw-output schedule.json); do

    package=$(echo "$line" | cut -d ':' -f 1)
    version=$(echo "$line" | cut -d ':' -f 2)

    if pixi list -x "^$package" 2> /dev/null | grep "No packages" -q -v; then
	echo "Updating $package"
	current_version=$(pixi list -x "^$package" --environment "$env" --json | jq '.[0].version' --raw-output)
	highest_version=$(echo -e "$version\n$current_version" | sort -V -r | head -n 1)
	if [ "$version" == '*' ] || [ "$highest_version" == "$current_version" ] ; then
	    pixi add --environment "$env" "$package>=$version"
	fi
    fi


done
