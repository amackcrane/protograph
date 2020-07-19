



# args: id
function remove {
    cp $file ${file}_bak
    jq --arg id $1 \
       'del(.nodes[] | select(.id==$id))' <$file >${file}_tmp \
	&& mv ${file}_tmp $file
}


id=$1
shift

# too lazy to clean up links; make the user do it
edges=$(source $path/edges.sh $id)
if test "$edges"; then
    echo "Clean up its edges first!"
    jq <<<"$edges"
    exit
fi

# confirm
to_rm=$(jq --arg id $id '.nodes[] | select(.id==$id)' <$file)

if test -z "$to_rm"; then
    echo "No matching nodes"
    exit
fi

jq <<<"$to_rm"
read -p "delete me? (y/n) > " confirm

if test $confirm != "y"; then
    echo "Not deleting"
    exit
fi

# remove
remove $id

# recurse for more arguments
if test $# -gt 0; then
    source $path/rm.sh $@
fi
