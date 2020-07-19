


keys=

while test $# -gt 0; do
    case $1 in
	*) keys="$keys "$1
	   ;;
    esac
    shift
done


if test -z "$keys"; then
    jq -c '.nodes[]' <$file
else
    for key in $keys; do
	# check for numeric id
	if test $key -eq $key 2> /dev/null; then
	    jq -c --arg id $key '.nodes[] | select(.id==$id)' <$file
	else
	    jq -c --arg key $key '.nodes[] | select(.text | contains($key))' <$file
	fi
    done
fi
