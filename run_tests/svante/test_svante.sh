#! /usr/bin/env bash

# $Header: /u/gcmpack/MITgcm_contrib/test_scripts/svante/test_svante.sh,v 1.1 2014/10/13 23:15:18 jmc Exp $

#  Test script for MITgcm to run on head-node of svante cluster

# defaults
#export PATH="$PATH:/usr/local/bin"
if [ -d ~/bin ]; then export PATH=$PATH:~/bin ; fi
#- to get case insensitive "ls" (and order of tested experiments)
export LC_ALL="en_US.UTF-8"
#  Turn off stack limit for FIZHI & AD-tests
ulimit -s unlimited

if test -f /etc/profile.d/modules.sh ; then
    . /etc/profile.d/modules.sh
fi

#- load standard modules:
module add fedora torque maui svante
module list

#- method to acces CVS:
cmdCVS='cvs -d :pserver:cvsanon@mitgcm.org:/u/gcmpack -q'

# checkOut=2 : download new code ;
#   =1 : update code       (if no existing code -> swith to 2)
#   =0 : use existing code (if no existing code -> swith to 2)
dInWeek=`date +%a`
dNam=`hostname -s`
QSUB="qsub"
QSTAT="qstat"
HERE="$HOME/test_${dNam}"
OUTP="$HERE/output"
SUB_DIR="$HERE/$dNam"
TESTDIR="/net/fs07/d1/testreport/test_${dNam}"
checkOut=1
option=

#tst_list='gads gadm gfo+rs gmpi gmth gmp2+rs ifc pgi'
#if test "x$dInWeek" = xSun ; then tst_list="$tst_list tlm oad" ; fi
tst_list='ifc+rs'

#option="-nc" ; checkOut=1
#option="-q"  ; checkOut=0

TODAY=`date +%d`
tdir=$TESTDIR
if test ! -d $TESTDIR ; then
   echo -n "Creating a working dir: $TESTDIR ..."
   /bin/rm -rf $TESTDIR
   mkdir $TESTDIR
   retVal=$?
   if test "x$retVal" != x0 ; then
      echo "Error: unable to make dir: $TESTDIR (err=$retVal ) --> Exit"
      exit 1
   fi
fi
cd $TESTDIR

#------------------------------------------------------------------------

#firstTst=`echo $tst_list | awk '{print $1}'`
#last_Tst=`echo $tst_list | awk '{print $NF}'`
for tt in $tst_list
do

  echo "================================================================"
  newCode=$checkOut
  typ=`echo $tt | sed 's/+rs//'`
  gcmDIR="MITgcm_$typ"
  tst2submit="run_tst_$typ"
  addExp=''
  #- check day and time:
  curDay=`date +%d` ; curHour=`date +%H`
  if [ $curDay -ne $TODAY ] ; then
    date ; echo "day is over => skip test $typ"
    continue
  fi
  if [ $curHour -ge 18 ] ; then
    date ; echo "too late to run test $typ"
    continue
  fi
  #- check for unfinished jobs
  job_exist=`$QSTAT -a | grep $USER | grep $tst2submit | wc -l`
  if test "x$job_exist" != x0 ; then
    echo $tst2submit
    echo "job '$tst2submit' still in queue:"
    $QSTAT -a | grep $USER | grep $tst2submit
    echo " => skip this test"
    continue
  fi
  #- clean-up old output files
  rm -f $OUTP/output_${typ}*.old $OUTP/$tst2submit.std???.old
  oldS=`ls $OUTP/output_${typ} $OUTP/$tst2submit.std??? 2> /dev/null`
  for xx in $oldS ; do mv $xx $xx.old ; done
  if test -d prev ; then
    #-- save previous summary: tr_out.txt* tst_2+2_out.txt
    oldS=`( cd ${gcmDIR}/verification ; ls t*_out.txt* ) 2> /dev/null`
    for xx in $oldS ; do
     #ss=`/bin/ls -l ${gcmDIR}/verification/$xx | awk '{print $6 $7}'`
      ss=`/bin/ls -l --time-style=iso ${gcmDIR}/verification/$xx | awk '{print $6}'`
      yy=`echo $xx | sed -e "s/\.txt.old/.$typ.c/" \
          -e "s/2_out.txt/2.$typ./" -e "s/\.txt/.$typ.r/"`
      cp -p ${gcmDIR}/verification/$xx prev/${yy}$ss
    done
  fi
  touch $OUTP/output_$typ

  #- clean and update code
  if [ $newCode -eq 1 ] ; then
    if test -d $gcmDIR/CVS ; then
      echo "cleaning output from $gcmDIR/verification :"	| tee -a $OUTP/output_$typ
  #- remove previous output tar files and tar & remove previous output-dir
      /bin/rm -f $gcmDIR/verification/??_${dNam}*_????????_?.tar.gz
      ( cd $gcmDIR/verification
        listD=`ls -1 -d tr_${dNam}_????????_? ??_${dNam}-${typ}_????????_? 2> /dev/null`
        for dd in $listD
        do
          if test -d $dd ; then
            tar -cf ${dd}".tar" $dd > /dev/null 2>&1 && gzip ${dd}".tar" && /bin/rm -rf $dd
            retVal=$?
            if test "x$retVal" != x0 ; then
               echo "ERROR in tar+gzip prev outp-dir: $dd"
               echo " on '"`hostname`"' (return val=$retVal) but continue"
            fi
          fi
        done )
      if test $tt != $typ ; then
        ( cd $gcmDIR/verification ; ../tools/do_tst_2+2 -clean ) >> $OUTP/output_$typ 2>&1
      fi
        ( cd $gcmDIR/verification ; ./testreport -clean ) >> $OUTP/output_$typ 2>&1
      echo "cvs update of dir $gcmDIR :"			| tee -a $OUTP/output_$typ
      ( cd $gcmDIR ; $cmdCVS update -P -d ) >> $OUTP/output_$typ 2>&1
      retVal=$?
      if test "x$retVal" != x0 ; then
        echo "cvs update on '"`hostname`"' fail (return val=$retVal) => exit"
        exit
      fi
    else
      echo "no dir: $gcmDIR/CVS => try a fresh check-out"	| tee -a $OUTP/output_$typ
      newCode=2
    fi
  fi
  #- download new code
  if [ $newCode -eq 2 ] ; then
    test -e $gcmDIR && rm -rf $gcmDIR
    echo -n "Downloading the MITgcm code using: $cmdCVS ..."	| tee -a $OUTP/output_$typ
    $cmdCVS co -P -d $gcmDIR MITgcm > /dev/null 2>&1
    echo "  done"						| tee -a $OUTP/output_$typ
    for exp2add in $addExp ; do
     echo " add dir: $exp2add (from Contrib:verification_other)"| tee -a $OUTP/output_$typ
     ( cd $gcmDIR/verification ; $cmdCVS co -P -d $exp2add \
                MITgcm_contrib/verification_other/$exp2add > /dev/null 2>&1 )
    done
    /usr/bin/find $gcmDIR -type d | xargs chmod g+rxs
    /usr/bin/find $gcmDIR -type f | xargs chmod g+r
  fi
#---------------------------------------------------
#-- set the testreport command:
  comm="./testreport"
# if test $typ = $typ = 'gads' -o  $typ = 'gadm' ; then
#   comm="$comm -adm"
# elif test $typ = 'oad' ; then
#   comm="$comm -oad"
# elif test $typ = 'tlm' ; then
#   comm="$comm -tlm"
# elif test $typ = 'gmth' -o  $typ = 'gmp2' ; then
#   export GOMP_STACKSIZE=400m
#   export OMP_NUM_THREADS=2
#   comm="$comm -mth"
# else
#   comm="$comm -md cyrus-makedepend"
#   comm="$comm -t hs94.cs-32x32x5"
# fi
  if test "x$dInWeek" = xSun ; then
    comm="$comm -fast"
 #else
 #  comm="$comm -devel"
  fi

#-- set the optfile (+ mpi & match-precision)
  MPI=0 ; MC=13
  case $typ in
   'gfo'|'gads'|'oad'|'tlm'|'gmth') comm="$comm -match $MC -devel"
			OPTFILE='../tools/build_options/linux_amd64_gfortran' ;;
   'ifc')		MPI=6; #comm="$comm -devel"
			OPTFILE='../tools/build_options/linux_amd64_ifort11' ;;
   'pgi')		MPI=6; #comm="$comm -devel"
			OPTFILE='../tools/build_options/linux_amd64_pgf77' ;;
   'gadm'|'gmpi'|'gmp2') MPI=6; comm="$comm -match $MC -devel"
                        if test $typ = 'gmp2' ; then MPI=3 ; fi
			OPTFILE='../tools/build_options/linux_amd64_gfortran' ;;
       *)		OPTFILE= ;;
  esac
#-- set MPI command:
# if test $MPI != 0 ; then
# fi

#-- set specific Env Vars:
 #if test $typ = 'oad' ; then
 #  source ~jmc/mitgcm/bin/setenv_OpenAD.sh
 #fi
  if test $typ = 'ifc' ; then
    module add intel
    module add mvapich2
  fi
 #if test $typ = 'pgi' ; then
 #fi

#-- run the testreport command:
  echo -n "Running testreport using"	| tee -a $OUTP/output_$typ
  if test "x$OPTFILE" != x ; then
    comm="$comm -of=$OPTFILE"
  fi
  if test $MPI != 0 ; then comm="$comm -MPI $MPI" ; fi
  echo " -norun option ('-nr'):"	| tee -a $OUTP/output_$typ
  comm="$comm -nr"
  if test "x$option" != x ; then comm="$comm $option" ; fi
  echo "  \"eval $comm\""		| tee -a $OUTP/output_$typ
  echo "======================"
  ( cd $gcmDIR/verification
    eval $comm >> $OUTP/output_$typ 2>&1
  )
 #sed -n "/^An email /,/^======== End of testreport / p" $OUTP/output_$typ
  sed -n "/^No results email was sent/,/^======== End of testreport / p" $OUTP/output_$typ
  echo ""				| tee -a $OUTP/output_$typ

#-- submit PBS script to run
  if test -e $SUB_DIR/${tst2submit}.pbs ; then
    echo " submit PBS bach script '$SUB_DIR/${tst2submit}.pbs'"	| tee -a $OUTP/output_$typ
    $QSUB $SUB_DIR/${tst2submit}.pbs				| tee -a $OUTP/output_$typ
    echo " job '$tst2submit' in queue:"				| tee -a $OUTP/output_$typ
    $QSTAT -a | grep $USER | grep $tst2submit			| tee -a $OUTP/output_$typ
  else
    echo " no PBS script '$SUB_DIR/${tst2submit}.pbs' to submit"| tee -a $OUTP/output_$typ
    continue
  fi

#-- also test restart (test 2+2=4)
# if test $tt != $typ ; then
#   echo "testing restart using:"	| tee -a $OUTP/output_$typ
#   comm="../tools/do_tst_2+2 -o $dNam -a jmc@mitgcm.org"
#   if test $MPI = 0 ; then
#     echo "  \"$comm\""		| tee -a $OUTP/output_$typ
#     echo "======================"
#     $comm >> $OUTP/output_$typ 2>&1
#   else
#     echo "  \"$comm -mpi\""		| tee -a $OUTP/output_$typ
#     echo "======================"
#     $comm -mpi >> $OUTP/output_$typ 2>&1
#   fi
#   echo ; cat tst_2+2_out.txt
#   echo
# fi
#--reset special setting:
  export OMP_NUM_THREADS=1

done