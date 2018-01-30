#!/bin/csh
#
#  $Header: /u/gcmpack/MITgcm/tools/example_scripts/ref_machine/setenv_OpenAD.csh,v 1.1 2017/05/09 00:56:08 jmc Exp $
#  $Name:  $

##########################################################
# This file is part of OpenAD released under the LGPL.   #
# The full COPYRIGHT notice can be found in the top      #
# level directory of the OpenAD distribution             #
##########################################################

# this set some env. vars such as "OPENADROOT"
#  (needed to generate and use Makefile)

#./tools/setenv/setenv.py --shell=csh > setenv.tmp~
set tmp_file="/tmp/setenv_OpenAD.$$"
#echo $tmp_file

set s1_file=$HOME/OpenAD/tools/setenv/setenv.py
set s2_file=/scratch/heimbach/OpenAD/tools/setenv/setenv.py
if   ( -f $s1_file ) then 
  set settings=$s1_file
else
 if ( -f $s2_file ) then 
  set settings=$s2_file
 else
  echo "Error: missing file OpenAD/tools/setenv/setenv.py"
  exit 1
 endif
endif
echo "settings='$settings'"

$settings --shell=csh > $tmp_file
if ( $status != 0 ) then
  echo  "Error executing: ./tools/setenv/setenv.py --shell=csh > $tmp_file"
else
  source $tmp_file
  if ( $status != 0 ) then
    echo "Error executing: source $tmp_file"
  else
    rm -f $tmp_file
  endif
endif
