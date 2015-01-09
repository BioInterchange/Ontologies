#!/usr/bin/env bash

TABLE=$1

count () {
  COLUMN=$1
  KEYWORD=$2

  cut -d ',' -f $COLUMN $TABLE | grep -E -o "“[^”]+” $KEYWORD" | sort | uniq | wc -l | tr -d ' '
}

# GFF3: extra handling of "Feature" and "Comment"
echo "GFF3"
echo "  column                    :  `count 2 column`"
echo "  attribute                 :  `count 2 attribute`"
echo "  pragma & other            :  `count 2 pragma`"
echo "                              + 2" # extra handling
echo ""

# GTF: extra handling of "Feature" and "Comment"
echo "GTF"
echo "  column                    :  `count 3 column`"
echo "  attribute                 :  `count 3 attribute`"
echo "  '##'s & other             :  `count 3 “##”-line`"
echo "                              + 2" # extra handling
echo ""

# GVF: extra handling of "Feature", "Comment"
echo "GVF"
echo "  column                    :  `count 4 column`"
echo "  attribute                 :  `count 4 attribute`"
echo "  pragma & other            :  `count 4 pragma`"
echo "                              + `count 4 key/value`"
echo "                              + 2" # extra handling
echo ""

# VCF: extra handling of "Feature"
echo "VCF"
echo "  column                    :   `count 5 column`"
echo "  additional information    :   `count 5 "additional information"`"
echo "  information field & other :   `count 5 "information field"`"
echo "                              + `count 5 key/value`"
echo "                              + 1" # extra handling
echo ""

