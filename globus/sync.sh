#!/bin/bash

SSH="ssh cli.globusonline.org"

taskId=$($SSH transfer --generate-id)

$SSH transfer --taskid=$taskId -s 3 --label=ISI-MIP_sync < filelist

