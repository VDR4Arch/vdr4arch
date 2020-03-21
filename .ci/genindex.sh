#!/bin/bash

target="$1"
repo="$2"

create_index() {
  index=$(ls --color=never --group-directories-first -1 -p --hide=index.html $1 | awk '{print "<a href=\"./"$1"\">"$1"</a>"}')

  echo "<!DOCTYPE html>
<html>
<head><title>Index of ${r}${d}</title></head>
<body>
<h1>Index of ${r}${d}</h1><hr><pre>
<a href="../">../</a>
${index}
</pre><hr></body>
</html>" > index.html
}

cd ${target}

d=${repo}/
create_index
r=${d}

for d in */; do
  (cd ${d}
  create_index)
done
