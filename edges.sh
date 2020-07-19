
ids=$($path/resolve-node.sh $@)




key=
id=
while test $# -gt 0; do
    case $1 in
	-s) key=$2
	    shift
	    ;;
	*) id=$1
	   ;;
    esac
    shift
done

if test $id; then
    jq --arg id $id '.links[] | select(.source==$id)' <$file \
       | source $path/print-edge.sh
    jq --arg id $id '.links[] | select(.target==$id)' <$file \
       | source $path/print-edge.sh
elif test $key; then
    ids=$(jq -r --arg key $key '.nodes[] | select(.text | contains($key)) | .id' <$file)
    if test "$ids"; then
	for id in "$ids"; do
	    jq --arg id "$id" '.links[] | select((.source==$id) or .target==$id)' <$file \
		| source $path/print-edge.sh
	done
    fi
    
else
    jq -c '.links[]' <$file | source $path/print-edge.sh
fi
