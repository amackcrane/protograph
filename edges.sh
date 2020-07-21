
ids=$(source $path/resolve-node.sh $@ 2>/dev/null)

if test -z "$ids"; then
    jq -c '.links[]' <$file | source $path/print-edge.sh
else
    for id in $ids; do
	jq --arg id $id '.links[] | select(.source==$id)' <$file \
	    | source $path/print-edge.sh
	jq --arg id $id '.links[] | select(.target==$id)' <$file \
	    | source $path/print-edge.sh
    done
fi
