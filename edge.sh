



# args: source, target (id)
function create-link {

    jq --arg src $1 --arg target $2 --arg text "$text" --arg valence $valence \
       '.links += [{source: $src, target: $target, text: $text, valence: $valence}]' \
       <$file >${file}_tmp \
	&& mv ${file}_tmp $file
    
}


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
	source $path/rm-edge.sh $src $target
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
