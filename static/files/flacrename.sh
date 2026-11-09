#!/bin/bash

FILE="$1"
NEWNAME=`metaflac --show-tag=TRACKNUMBER $FILE | sed -e "s/TRACKNUMBER=//"`
NEWNAME+=" - "
NEWNAME+=`metaflac --show-tag=TITLE $FILE | sed -e "s/TITLE=//"`
NEWNAME=`echo $NEWNAME | sed -e "s/\//_/"`
echo $NEWNAME
mv "$FILE" "$NEWNAME.flac"
