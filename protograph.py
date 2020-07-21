

import networkx as nx
import json
import plotly.graph_objects as go
import sys
import numpy as np
import math

# load
path = sys.argv[1]
name = path.split('/')[-1]

with open(path, 'r') as f:
    data = json.loads(f.read())

G = nx.readwrite.json_graph.node_link_graph(data, directed=True, multigraph=False)

focal_nodes = []
depth = None
trawl = lambda _set, member: _set.union(G.successors(member)).union(G.predecessors(member))

args = iter(sys.argv[2:])
for arg in args:
    if arg == "--depth":
        depth = int(next(args))
    elif arg == "--upstream":
        trawl = lambda _set, member: _set.union(G.predecessors(member))
    elif arg == "--downstream":
        trawl = lambda _set, member: _set.union(G.successors(member))
    else:
        try:
            int(arg)
            focal_nodes.append(arg)
        except ValueError:
            print(f"Argument {arg} not recognized!")
            sys.exit(1)

if not depth:
    depth = 2
            
if len(focal_nodes) > 0:
    # filter graph to neighborhood
    keepers = set(focal_nodes)
    for _ in range(depth):
        for k in keepers.copy():
            keepers = trawl(keepers, k)
    droppers = np.setdiff1d(G.nodes, list(keepers)) # np doesn't like sets...
    G.remove_nodes_from(droppers)

# visualize

try:
    pos = nx.drawing.layout.planar_layout(G)
except nx.exception.NetworkXException:
    #pos = nx.drawing.layout.spectral_layout(G)
    pos = nx.drawing.layout.kamada_kawai_layout(G)
    pos = nx.drawing.layout.spring_layout(G, k=100/math.sqrt(len(G.nodes)), iterations=1000, threshold=2e-3, pos=pos)


    
def arrow(x0, y0, x1, y1):
    vector = np.array((x1-x0, y1-y0))
    midpoint = np.array([(x0 + x1)/2, (y1+y0)/2])
    scale = .05
    orthpoint = midpoint - scale * vector
    antivector = scale * np.array([vector[1], -1 * vector[0]])
    return [orthpoint + antivector, midpoint, orthpoint - antivector,
            orthpoint + antivector, (None, None)]

    
# Mostly lifted from plotly docs
# edited to make edges separate traces s.t. can vary colors
edges_x = []
edges_y = []
texts = []
edge_colors = []
for edge in G.edges():
    x0, y0 = pos[edge[0]]
    x1, y1 = pos[edge[1]]
    x = [x0, (x0+x1)/2, x1]
    y = [y0, (y0+y1)/2, y1]
    
    edges_x.append(x)
    edges_y.append(y)
    # try throwing text in for hovering?    
    text = G.edges[edge[0], edge[1]]['text']
    texts.append(["", text, ""])
    # color from valence
    c = int(G.edges[edge[0], edge[1]]['valence'])
    edge_colors.append(c)

arrows_x = []
arrows_y = []
arrow_colors = []
for edge in G.edges():
    ar = arrow(*pos[edge[0]], *pos[edge[1]])
    x,y = zip(*ar)
    arrows_x.append(x)
    arrows_y.append(y)
    # color
    c = int(G.edges[edge[0], edge[1]]['valence'])
    arrow_colors.append(c)

# translate to colors
edge_colors = np.where(np.equal(edge_colors, -1), 'red', np.where(np.equal(edge_colors, 1), 'green', 'gray'))
arrow_colors = np.where(np.equal(arrow_colors, -1), 'red', np.where(np.equal(arrow_colors, 1), 'green', 'gray'))

edge_traces = []
for x,y,t,c in zip(edges_x, edges_y, texts, edge_colors):
    edge_traces.append(go.Scatter(
        x=x, y=y,
        line=dict(width=0.5,
                  color=c
        ),
        hovertemplate='%{text}<extra></extra>', text=t,
        mode='lines'))

arrow_traces = []
for x,y,c in zip(arrows_x, arrows_y, arrow_colors):
    arrow_traces.append(go.Scatter(
        x=x, y=y,
        line=dict(width=0.5, color=c),
        mode='lines',
        hoverinfo='skip'))

node_x = []
node_y = []
node_text = []
node_color = []
for node in G.nodes():
    x, y = pos[node]
    node_x.append(x)
    node_y.append(y)
    node_text.append(G.nodes[node]['text'])
    node_color.append(int(G.nodes[node]['valence']))

node_trace = go.Scatter(
    x=node_x, y=node_y,
    mode='markers+text',
    #hovertemplate='%{text}<extra></extra>',
    hoverinfo='skip',
    text=node_text,
    textposition='top center',
    marker=dict(
        size=10,
        line_width=2,
        color=node_color,
        colorscale=['red','gray', 'green'])
)




fig = go.Figure(data=arrow_traces + edge_traces + [node_trace],
                layout=go.Layout(
                    title=f'{name}:',
                    titlefont_size=16,
                    showlegend=False,
                    hovermode='closest',
                    hoverdistance=500,
                    margin=dict(b=20,l=5,r=5,t=40),
                    annotations=[ dict(
                        showarrow=False,
                        xref="paper", yref="paper",
                        x=0.005, y=-0.002 ) ],
                    xaxis=dict(showgrid=False, zeroline=False, showticklabels=False),
                    yaxis=dict(showgrid=False, zeroline=False, showticklabels=False))
)
fig.show()
