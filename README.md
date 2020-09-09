# protograph

Draw network diagrams where nodes and edges have arbitrary text fields attached. Input data via command line; 'render' pulls up a visualization in the browser.

## Usage

to list saved graphs: `pg ls`  
to enter interactive prompt: `pg <graphname>`

```
> node <text> [+ | -]
> edge <src_id> <target_id> [<text>] [+ | -]
```
- create node or directed edge
- text may be multiple words, needn't be quoted
- +/- cause nodes/edges to be colored green/red in rendering

```
> nodes [<search_key> [<search_key> [...]]]
```
- if multiple keys, returns union
- doesnt support quoted multiword keys

```
> edges [<node_id_or_search_key> [...]]
```
- print all edges pertaining to all nodes matching one or more ids or search keys

```
> rm <node_id>
> rm-edge <src_id> <target_id>
```

```
> render [<node_id_or_text> [--depth <int>] [--upstream | --downstream]] 
```
- render network with plotly in browser
- optionally choose focal node, length of paths to include, restrict on edge direction
- may be invoked directly from command line as 'pg <graph> render ...'

```
> edit
```
- pull up data json in text file, for buggy things



## Setup

* install [jq](https://github.com/stedolan/jq/releases)
* ensure you have python3
* put the repo somewhere on your filesystem
* edit the 'pg' script to point 'path' variable to the local repo
  * note no spaces around '=' in bash
* copy 'pg' to somewhere on the search path, like /usr/local/bin on unix or \Windows\system32 on windows
* install python libraries
  * pip3 install -r requirements.txt
  
I'm hoping this will work on windows with git bash or similar, but haven't tried it.
