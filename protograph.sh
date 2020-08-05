#!/bin/bash


cat <<EOF >/tmp/pg_help

protograph

to list saved graphs: 'pg ls'
to start: 'pg <graphname>'

node <text> [+ | -]
edge <src_id> <target_id> [<text>] [+ | -]
- create node or directed edge
- text may be multiple words, needn't be quoted
- +/- cause nodes/edges to be colored green/red in rendering

nodes [<search_key> [<search_key> [...]]]
- if multiple keys, returns union
- doesnt support quoted multiword keys

edges [<node_id_or_search_key> [...]]
- print all edges pertaining to all nodes matching one or more ids or search keys

rm <node_id>

rm-edge <src_id> <target_id>

render [<node_id_or_text> [--depth <int>] [--upstream | --downstream]] 
- render network with plotly in browser
- optionally choose focal node, length of paths to include, restrict on edge direction

edit
- pull up data json in text file, for buggy things

loose ends:
- currently doesn't warn if creating redundant node
- edges can be created for nodes that don't exist, which breaks 'render'


EOF


if test -z $1; then
    echo "'help' for usage"
    exit
fi


if test -z $file; then
    echo "Must be invoked via 'pg'!"
    cat /tmp/pg_help
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

	depth=
	updown=
	keys=()
	while test $# -gt 0; do
	    case $1 in
		--depth)
		    depth="--depth "$2
		    shift
		    ;;
		--upstream)
		    updown=--upstream
		    ;;
		--downstream)
		    updown=--downstream
		    ;;
		*)
		    keys+=($1)
		    ;;
	    esac
	    shift
	done

	ids=$(source $path/resolve-node.sh ${keys[@]} --validate 2>/tmp/err)
	
	# don't render if node resolution failed...
	if test -s /tmp/err; then
	    cat /tmp/err
	else
	    python3 $path/protograph.py $file $ids $depth $updown &
	fi
	;;
    edit)
	source $path/edit.sh $@
	;;
    help)
	cat /tmp/pg_help
	;;
    *)
	echo "not recognized"
	echo "'help' for usage"
	;;
esac
