#!/usr/bin/bash

#source /BashLoger/BashLoger.sh ${USER}/bashinator.log [Bashinator] INFO
source "./bashinator.sh"

FilePath=$1

RawJson=$(cat "$FilePath")

if ! IsJSON "$RawJson"
then
    echo "Invalid JSON"
    exit 1
fi

echo "Valid JSON"
exit 0