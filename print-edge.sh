
# in: collection of link objects?

# shoot stdin thru jq
input=$(jq <&0 | jq -s 'sort_by(.target)')

# grab something to iterate with
indices=$(jq 'keys[]' <<<$input)

for ind in $indices
do
    entry=$(jq -r --argjson ind $ind '.[$ind]' <<<$input)
    # grab source node text
    source_id=$(jq -r '.source' <<<$entry)
    source=$(jq -r --arg id $source_id '.nodes[] | select(.id==$id) | .text' <$file)
    # grab target node text
    target_id=$(jq -r '.target' <<<$entry)
    target=$(jq -r --arg id $target_id '.nodes[] | select(.id==$id) | .text' <$file)
    # edge text
    text=$(jq -r --arg ind $ind '.text' <<<$entry)
    valence=$(jq -r --arg ind $ind '.valence' <<<$entry)
    case $valence in
	-1) valence="-"
	    ;;
	1) valence="+"
	   ;;
	0) valence=
	   ;;
    esac

    # print json-style, replacing ids w/ names
    #jq -c --arg s "$source" --arg t "$target" '. + {"source": $s, "target": $t}' <<<$entry
    
    # print more evocatively
    # \033[31m \033[0m
    printf "\033[32m%s\033[0m (%s) --> \033[32m%s\033[0m (%s) \n %s  %s\n" "$source" "$source_id" "$target" "$target_id" "$valence" "$text"

done
