


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

