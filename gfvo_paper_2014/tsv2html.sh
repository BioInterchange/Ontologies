#!/usr/bin/env bash

echo '<table>'
sed 's/“/\&quot;/g' $1 | tr -d "\r" | sed 's/”/\&quot;/g' | sed 's/^/<tr><td>/' | sed 's/,*$/<\/td><\/tr>/' | sed 's/,/<\/td><td>/g'
echo '</table>'

