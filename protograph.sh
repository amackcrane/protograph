#!/bin/bash


node=
link=
list=
list_link=
render=
remove=
remove_link=
edit=


help_text=$(cat <<EOF

protograph

to start: 'pg <graphname>'

node <text> [+ | -]
link <src_id> <target_id> [<text>] [+ | -]
- for both 'node' and 'link', text arg should be unquoted, may be multiple words
- links are directed for now
- +/- cause nodes/links to be colored green/red in rendering, respectively
list [<search_key> [<search_key> [...]]]
- if multiple keys, returns union
- doesnt support quoted multiword keys
list-link [<node_id> | -s <search_key>]
rm <node_id>
rm-link <src_id> <target_id>
render
- render network with plotly in browser
edit
- pull up data json in text file, for buggy things

loose ends:
- currently doesn't warn if creating redundant node
- edges can be created for nodes that don't exist, which breaks 'render'


EOF
	   )"\n\n"


if test -z $1; then
    printf "$help_text"
    exit
fi


case $1 in
    node)
	node=t
	;;
    rm)
	remove=t
	;;
    rm-link)
	remove_link=t
	;;
    link)
	link=t
	;;
    list)
	list=t
	;;
    list-link)
	list_link=t
	;;
    render)
	render=t
	;;
    edit)
	edit=t
	;;
    *)
	printf "$help_text"
	;;
esac
shift


if test -z $file; then
    echo "Must be invoked via 'pg'!"
    printf "$help_text"
fi

if ! test -e $file; then
    jq -n '{nodes: [], links: []}' >$file
fi


function get_id {

    existing_ids=$(jq -r '.nodes[] | .id' <$file)
    
    for id in $(seq 1 10000); do
	if ! [[ "$existing_ids" =~ $id ]]; then
	    echo $id
	    success=t
	    break
	fi
    done

    if test -z $success; then
	echo "get_id failed!!"
    fi
    
    
    }

if test $node; then

    text=
    valence=
    while test $# -gt 0; do
	case $1 in
	    -)
		valence=-1
		;;
	    +)
		valence=1
		;;
	    *)
		if test "$text"; then
		    text="$text "$1
		else
		    text=$1
		fi
		;;
	esac
	shift
    done
    
    if test -z "$text"; then
	printf "$help_text"
	exit
    fi

    if test -z "$valence"; then
	valence=0
    fi

    # look for available ID
    id=$(get_id)
    echo $id

    jq --arg id $id --arg text "$text" --arg valence $valence \
       '.nodes += [{id: $id, text: $text, valence: $valence}]' \
       <$file >${file}_tmp \
	&& mv ${file}_tmp $file
    
fi

# args: source, target (id)
function create-link {

    jq --arg src $1 --arg target $2 --arg text "$text" --arg valence $valence \
       '.links += [{source: $src, target: $target, text: $text, valence: $valence}]' \
       <$file >${file}_tmp \
	&& mv ${file}_tmp $file
    
}


if test $link; then
    src=$1
    target=$2
    shift 2

    text=
    valence=
    while test $# -gt 0; do
	case $1 in
	    -) valence=-1
	       ;;
	    +) valence=1
	       ;;
	    *)
		if test "$text"; then
		    text="$text "$1
		else
		    text=$1
		fi
		;;
	esac
	shift
    done
    
    if test -z $src -o -z $target; then
	printf "$help_text"
	exit
    fi

    if test -z "$valence"; then
	valence=0
    fi

    existing=$(jq --arg src $src --arg target $target \
		  '.links[] | select((.source==$src) and .target==$target)' <$file)
    if test "$existing"; then
	jq <<<"$existing"
	read -p "Link exists; modify? (y/n) > " modify
	if test $modify == "y"; then
	    $path/protograph.sh rm-link $src $target
	else
	    echo "Fine then, doing nothing"
	    exit
	fi
    fi

    create-link $src $target

    # this would be nice, but I don't have a way to visualize directed edges yet, so whatever
#    if test -z $directed; then
#	create-link $target $src
#    fi

fi

if test $list; then

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

fi

if test $list_link; then

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
	jq --arg id $id '.links[] | select(.source==$id)' <$file
	jq --arg id $id '.links[] | select(.target==$id)' <$file
    elif test $key; then
	ids=$(jq -r --arg key $key '.nodes[] | select(.text | contains($key)) | .id' <$file)
	if test "$ids"; then
	    for id in "$ids"; do
		jq --arg id "$id" '.links[] | select((.source==$id) or .target==$id)' <$file
	    done
	fi
	
    else
	jq -c '.links[]' <$file
    fi
    

fi



# args: id
function remove {
    cp $file ${file}_bak
    jq --arg id $1 \
       'del(.nodes[] | select(.id==$id))' <$file >${file}_tmp \
	&& mv ${file}_tmp $file
}

if test $remove; then
    id=$1
    shift

    # too lazy to clean up links; make the user do it
    links=$($path/protograph.sh list-link $id)
    if test "$links"; then
	echo "Clean up its links first!"
	jq <<<"$links"
	exit
    fi

    # confirm
    to_rm=$(jq --arg id $id '.nodes[] | select(.id==$id)' <$file)

    if test -z "$to_rm"; then
	echo "No matching links"
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

    if test $# -gt 0; then
	$path/protograph rm $@
    fi

fi


function remove_link {
    cp $file ${file}_bak
    jq --arg src $1 --arg target $2 \
       'del(.links[] | select((.source==$src) and .target==$target))' <$file >${file}_tmp \
	&& mv ${file}_tmp $file

}

if test $remove_link; then
    src=$1
    target=$2

    # confirm
    to_rm=$(jq --arg src $src --arg target $target \
	       '.links[] | select((.source==$src) and .target==$target)' <$file)

    if test -z "$to_rm"; then
	echo "No matching links"
	exit
    fi

    $path/protograph.sh list $src
    $path/protograph.sh list $target
    jq <<<"$to_rm"
    read -p "delete me? (y/n) > " confirm

    if test "$confirm" != "y"; then
	echo "Not deleting"
	exit
    fi

    # remove
    remove_link $src $target



fi


if test $render; then
    export PYTHONWARNINGS=ignore
    python3 /Users/austen/Desktop/the_thing/projects/wanting_to_know_the_answer/graph/protograph.py $file &
fi


if test $edit; then
    emacs $file &
fi
