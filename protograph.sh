#!/bin/bash


help_text=$(cat <<EOF

protograph

to list saved graphs: 'pg ls'
to start: 'pg <graphname>'

node <text> [+ | -]
edge <src_id> <target_id> [<text>] [+ | -]
- for both 'node' and 'link', text arg should be unquoted, may be multiple words
- edges are directed for now
- +/- cause nodes/links to be colored green/red in rendering, respectively
nodes [<search_key> [<search_key> [...]]]
- if multiple keys, returns union
- doesnt support quoted multiword keys
edges [<node_id> | -s <search_key>]
rm <node_id>
rm-edge <src_id> <target_id>
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


if test -z $file; then
    echo "Must be invoked via 'pg'!"
    printf "$help_text"
fi

if ! test -e $file; then
    jq -n '{nodes: [], links: []}' >$file
fi


subcommand=$1
shift

case $subcommand in
    node)
	source $path/node.sh $@
	;;
    rm)
	source $path/rm.sh $@
	;;
    rm-edge)
	source $path/rm-edge.sh $@
	;;
    edge)
	source $path/edge.sh $@
	;;
    nodes)
	source $path/nodes.sh $@
	;;
    edges)
	source $path/edges.sh $@
	;;
    render)
	export PYTHONWARNINGS=ignore
	python3 $path/protograph.py $file $@ &
    ;;
    edit)
	source $path/edit.sh $@
	;;
    *)
	printf "$help_text"
	;;
esac
