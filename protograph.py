

import networkx as nx
import json
import plotly.graph_objects as go
import sys


# load
path = sys.argv[1]

with open(path, 'r') as f:
    data = json.loads(f.read())

G = nx.readwrite.json_graph.node_link_graph(data, directed=True)


# visualize

pos = nx.drawing.layout.planar_layout(G)


# Mostly lifted from plotly docs
edge_x = []
edge_y = []
info = []
for edge in G.edges():
    x0, y0 = pos[edge[0]]
    x1, y1 = pos[edge[1]]
    edge_x.append(x0)
    edge_x.append((x0 + x1)/2)
    edge_x.append(x1)
    edge_x.append(None)
    edge_y.append(y0)
    edge_y.append((y0+y1)/2)
    edge_y.append(y1)
    edge_y.append(None)
    # try throwing text in for hovering?
    text = G.edges[edge[0], edge[1], 0]['text']
    info.extend(["", text, "", ""])

edge_trace = go.Scatter(
    x=edge_x, y=edge_y,
    line=dict(width=0.5, color='#888'),
    hovertemplate='%{text}<extra></extra>', text=info,
    mode='lines')

node_x = []
node_y = []
node_text = []
for node in G.nodes():
    x, y = pos[node]
    node_x.append(x)
    node_y.append(y)
    node_text.append(G.nodes[node]['text'])

node_trace = go.Scatter(
    x=node_x, y=node_y,
    mode='markers+text',
    #hovertemplate='%{text}<extra></extra>',
    hoverinfo='skip',
    text=node_text,
    textposition='top center',
    marker=dict(
        showscale=True,
        # colorscale options
        #'Greys' | 'YlGnBu' | 'Greens' | 'YlOrRd' | 'Bluered' | 'RdBu' |
        #'Reds' | 'Blues' | 'Picnic' | 'Rainbow' | 'Portland' | 'Jet' |
        #'Hot' | 'Blackbody' | 'Earth' | 'Electric' | 'Viridis' |
        colorscale='YlGnBu',
        reversescale=True,
        color=[],
        size=10,
        colorbar=dict(
            thickness=15,
            title='Node Connections',
            xanchor='left',
            titleside='right'
        ),
        line_width=2))




fig = go.Figure(data=[edge_trace, node_trace],
                layout=go.Layout(
                    title='<br>Network graph made with Python',
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
