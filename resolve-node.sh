

# in: integer or text
# out: node id or complaint
# without --unique flag, doesn't complain for multiple matches
# --validate -- check that each id or search key exists
# maybe a quiet flag too? to avoid 2>/dev/null?

ids=()
keys=()
unique=
validate=

while test $# -gt 0; do
    case $1 in
	--validate) validate=t
		    ;;
	--unique) unique=t
		  # note unique implies validate
		  ;;
	*)
	    # check for integer
	    if test $1 -eq $1 2>/dev/null; then
		ids+=($1)
            else
		keys+=($1)
	    fi
	    ;;
    esac
    shift
done


if test $unique; then

    if test -z "$ids" -a -z "$keys"; then
	echo "Didn't get any node identifiers in resolve-node.sh" >&2	
	exit
    fi

    
    if test "$ids" -a "$keys"; then
	echo "Too many arguments given to resolve unique node! (resolve-node.sh)" >&2
	exit
    fi
    
    if test "$ids"; then
	# check if singular
	if test ${#ids[@]} -gt 1; then
	    echo "Too many ids given" >&2
	    exit
	fi
	# check if exists!!
	id=${ids[0]}
	if test $(jq --arg id $id '.nodes[] | select(.id==$id)' <$file | jq -s 'length') -gt 0
	then
	    echo $id
	else
	    echo "Node id not found (resolve-node.sh)" >&2
	    exit
	fi
    else
	matches=$(jq --arg key "$key" '.nodes[] | select(.text | contains($key))' <$file \
		      | jq -s 'length')
	if test $matches -gt 1; then
	    echo "Ambiguous! try longer key (resolve-node.sh)" >&2
	    exit
	elif test $matches -lt 1; then
	    echo "No matches! (resolve-node.sh)" >& 2
	    exit
	fi

	jq -r --arg key "$key" '.nodes[] | select(.text | contains($key)) | .id' <$file 
    fi
    
else
    # not unique
    resolved_ids=(${ids[@]})
    
    for key in ${keys[@]}; do
	resolved_ids+=($(jq -r --arg key "$key" '.nodes[] | select(.text | contains($key)) | .id' <$file))
    done

    if test $validate; then
	for id in ${resolved_ids[@]}; do
	    if test $(jq --arg id $id '.nodes[] | select(.id==$id)' <$file | jq -s 'length')\
		    -ne 1; then
		echo "IDs failed to validate" >&2
		exit
	    fi
	done
    fi

    echo ${resolved_ids[@]}
    
fi


