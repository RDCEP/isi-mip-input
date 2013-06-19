#!/bin/bash

SSH="ssh cli.globusonline.org"

taskId=$($SSH transfer --generate-id)

$SSH transfer --taskid=$taskId -s 2 --label=ISI-MIP_sync --delete < filelist

