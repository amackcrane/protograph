# protograph

Draw network diagrams where nodes and edges have arbitrary text fields attached

usage example:

```
<prompt>:<dir> <user>$ pg
using /<path-to-repo>/data/test
> node hi how are you
1
> list
{"id":"1","text":"hi how are you"}
> node sunrise sunset
2
> list sun
{"id":"2","text":"sunrise sunset"}
> link 1 2 diurnal greeting
> list-link
{
  "source": "1",
  "target": "2",
  "text": " diurnal greeting"
}
> rm 2
Clean up its links first!
{
  "source": "1",
  "target": "2",
  "text": " diurnal greeting"
}
> rm-link 1 2
{
  "source": "1",
  "target": "2",
  "text": " diurnal greeting"
}
delete me? (y/n) > y
> rm 2
{
  "id": "2",
  "text": "sunrise sunset"
}
delete me? (y/n) > y
>
```

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
