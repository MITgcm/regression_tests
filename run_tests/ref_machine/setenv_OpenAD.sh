#! /usr/bin/env bash

##########################################################
# This file is part of OpenAD released under the LGPL.   #
# The full COPYRIGHT notice can be found in the top      #
# level directory of the OpenAD distribution             #
##########################################################

# this set some env. vars such as "OPENADROOT"
#  (needed to generate and use Makefile)

#./tools/setenv/setenv.py --shell=sh > setenv.tmp~
tmp_file="/tmp/setenv_OpenAD.$$"
#echo $tmp_file

s1_file=$HOME/OpenAD/tools/setenv/setenv.py
s2_file=/scratch/heimbach/OpenAD/tools/setenv/setenv.py
if   test -f $s1_file ; then settings=$s1_file
elif test -f $s2_file ; then settings=$s2_file
else
  echo "Error: missing file OpenAD/tools/setenv/setenv.py"
  exit 1
fi
echo "settings='$settings'"

$settings --shell=sh > $tmp_file
if [ $? -ne 0 ] 
then 
 echo "Error executing ./tools/setenv/setenv.py --shell=sh > $tmp_file"
else 
  source $tmp_file
  if [ $? -ne 0 ]
  then
    echo "Error executing source $tmp_file"
  else 
    rm -f $tmp_file
  fi
fi
