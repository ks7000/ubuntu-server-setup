#!/bin/bash
#Write the shell program which produces  a report from the output of ls -l in the following format
# file1
# file2
# [DIR] test/
# Total regular files : 7
# Total directories : 4
# Total symbolic links : 0
# Total size of regular files : 2940
# --------------------------------------------------------------------
# This is a free shell script under GNU GPL version 2.0 or above
# Copyright (C) 2005 nixCraft project.
# Feedback/comment/suggestions : http://cyberciti.biz/fb/
# -------------------------------------------------------------------------
# This script is part of nixCraft shell script collection (NSSC)
# Visit http://bash.cyberciti.biz/ for more information.
# -------------------------------------------------------------------------
rf=0
dir=0
syml=0
totsize=0
output=""
for f in *
do
        if [ -f $f ]
        then
                output=$f
                ((rf++))
                size=$(ls -l "${f}" | awk '{ print $5}')
                totsize=$((totsize+size))
        fi
        if [ -d $f ]
        then
                output="[DIR] $f/"
                ((dir++))
        fi
        if [ -L $f ]
        then
                output="[LINK] $f@"
                ((syml++))
        fi
        echo $output
done

echo "Total regular files : $rf"
echo "Total directories : $dir"
echo "Total symbolic links : $syml"
echo "Total size of regular files : $totsize"
