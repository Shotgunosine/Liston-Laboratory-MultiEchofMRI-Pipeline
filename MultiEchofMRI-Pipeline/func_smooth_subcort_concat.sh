#!/bin/bash

MEDIR=$1
Subject=$2
StudyFolder=$3
Subdir="$StudyFolder"/"$Subject"


# fresh workspace dir.
rm -rf "$Subdir"/workspace/ #> /dev/null 2>&1
mkdir "$Subdir"/workspace/ #> /dev/null 2>&1

# create temp. find_epi_params.m 
cp -rf "$MEDIR"/res0urces/smooth_subcort_concat.m \
"$Subdir"/workspace/temp.m
FOO="$Subdir"/workspace/bar

# cd before making temp to avoid races.
cd "$Subdir"/workspace/ # run script via Matlab 
# define some Matlab variables;
echo "addpath(genpath('/data/MLDSST/nielsond/target_test/other_repos/jsonlab')); addpath(genpath('${MEDIR}'))" | cat - "$Subdir"/workspace/temp.m > $FOO && mv $FOO "$Subdir"/workspace/temp.m
echo Subdir=["'$Subdir'"] | cat - "$Subdir"/workspace/temp.m >> $FOO && mv $FOO "$Subdir"/workspace/temp.m # > /dev/null 2>&1 		
matlab -nodesktop -nosplash -r "temp; exit" # > /dev/null 2>&1

# delete some files;
# rm -rf "$Subdir"/workspace/
cd "$Subdir" # go back to subject dir. 