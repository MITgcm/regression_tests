#! /usr/bin/env bash

#- the command line Oliver gave me to update script "tst_2+2":
#  > cp tst_2+2 tst_2+2.cp
#  > mk_tst_2+2.cp tst_2+2.cp
#  and check:
#  > diff tst_2+2.cp tst_2+2

sed -i 's/^    mv \*\.data \*\.meta.*$/    cp -a *.data *.meta $1 \&\& rm -f *.data *.meta/' $1
