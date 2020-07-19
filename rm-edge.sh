


function remove_edge {
    cp $file ${file}_bak
    jq --arg src $1 --arg target $2 \
       'del(.links[] | select((.source==$src) and .target==$target))' <$file >${file}_tmp \
	&& mv ${file}_tmp $file

}


src=$1
target=$2

if test -z "$src" -o -z "$target"; then
    echo "Need source and target to remove edge"
    exit
fi

# confirm
to_rm=$(jq --arg src $src --arg target $target \
	   '.links[] | select((.source==$src) and .target==$target)' <$file)

if test -z "$to_rm"; then
    echo "No matching edges"
    exit
fi

source $path/nodes.sh $src
source $path/nodes.sh $target
jq <<<"$to_rm"
read -p "delete me? (y/n) > " confirm

if test "$confirm" != "y"; then
    echo "Not deleting"
    exit
fi

# remove
remove_edge $src $target


