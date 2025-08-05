REPO='savente93/spec-zero-tools'
gh release download -R "$REPO" --pattern schedule.json --clobber
for env in $(pixi workspace environment ls | awk '/^-.*:\w*/{print $0}' | tr -d "-" | tr -d ":"); do

    echo "Updating packages in $env environment"

    for line in $(jq 'map(select(.start_date |fromdateiso8601 |tonumber  < now))| sort_by("start_date") | reverse | .[0].packages | to_entries | map(.key + ":" + .value)[]' --raw-output schedule.json); do

	package=$(echo "$line" | cut -d ':' -f 1)
	version=$(echo "$line" | cut -d ':' -f 2)

	echo "searching if env contains $package"

	if pixi list -x "^$package" --environment "$env" &>/dev/null| grep "No packages" -q -v; then
	    echo "Updating $version"
	    current_version=$(pixi list -x "^$package" --environment "$env" --json | jq '.[0].version' --raw-output)
	    highest_version=$(echo -e "$version $current_version" | sort -V -r | head -n 1)
	    if [ "$highest_version" -ne "$current_version" || "$version" -eq "*" ]; then
		pixi add --environment "$env" "$package>=$version"
	    fi
	fi


    done
    echo "Done updating $env"
done
