#! /usr/bin/env bash

# $Header:  $
# $Name:  $

#- create a copy of current Makefile with additional FFLAGS
if test Makefile_syntax -ot Makefile ; then
   echo -n '-- using new "Makefile_syntax",'
   sed 's/^FFLAGS =.*$/& -syntax-only/' Makefile > Makefile_syntax
else
   echo -n '-- use prev. "Makefile_syntax",'
fi
#- move away object files and remove "__genmod.mod" files:
( mkdir tmp ; ~/bin/rn .o .oSv .c ; mv -f *.o tmp
    ~/bin/rn .oSv .o ; rm -f *__genmod.mod ) > /dev/null 2>&1
#- make:
  echo " exec 'make -f Makefile_syntax $*':"
  make -f Makefile_syntax $*
  RETVAL=$?
#- move back object files:
( mv -f tmp/* . ; rmdir tmp )  > /dev/null 2>&1

exit $RETVAL
