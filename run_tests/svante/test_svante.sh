#! /usr/bin/env bash

# $Header:  $

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
#   =3 : skip download but, if sepDir, use a new copy
#   =1 : update code       (if no existing code -> swith to 2)
#   =0 : use existing code (if no existing code -> swith to 2)
dInWeek=`date +%a`
dName=`hostname -s`
QSUB="qsub"
QSTAT="qstat"
HERE="$HOME/test_${dName}"
OUTP="$HERE/output"
SUB_DIR="$HERE/$dName"
TESTDIR="/net/fs07/d1/testreport/test_${dName}"
checkOut=2
option=

#tst_list='gads gadm gfo+rs gmpi gmth gmp2+rs ifc pgi'
#if test "x$dInWeek" = xSun ; then tst_list="$tst_list tlm oad" ; fi
tst_list='ifc'

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
  oldS=`ls $OUTP/output_${tt} $OUTP/$tst2submit.std??? 2> /dev/null`
  for xx in $oldS ; do mv $xx $xx.old ; done
  if test -d prev ; then
    #-- save previous summary: tr_out.txt* tst_2+2_out.txt
    oldS=`( cd ${gcmDIR}/verification ; ls tr_out.txt* tst_2+2_out.txt ) 2> /dev/null`
    for xx in $oldS ; do
      yy=`echo $xx | sed "s/\.txt/.$typ/"`
      cp -p ${gcmDIR}/verification/$xx prev/$yy
    done
  fi
 #if test -d $HERE/prev ; then
  #  oldS=`ls -t ${gcmDIR}/verification/tr_${dName}_*/summary.txt 2> /dev/null | head -1`
  #  if test "x$oldS" != x ; then cp -p -f $oldS $HERE/prev/tr_out.$typ ; fi
  #  # sed '/^[YN] [YN] [YN] [YN]/ s/ \. //g' $oldS > tr_out.$typ
  # if test $tt != $typ ; then
  #  oldS=`ls -t ${gcmDIR}/verification/rs_${dName}_*/summary.txt 2> /dev/null | head -1`
  #  if test "x$oldS" != x ; then cp -p -f $oldS $HERE/prev/rs_out.$typ ; fi
  # fi
 #fi
  touch $OUTP/output_$tt

  #- clean and update code
  if [ $newCode -eq 1 ] ; then
    if test -d $gcmDIR/CVS ; then
#- remove previous output tar files and tar & remove previous output-dir
      /bin/rm -f $gcmDIR/verification/??_${dNam}-${typ}_????????_?.tar.gz
      ( cd $gcmDIR/verification
        listD=`ls -1 -d ??_${dNam}-${typ}_????????_? 2> /dev/null`
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
        ( cd $gcmDIR/verification ; ../tools/do_tst_2+2 -clean )
      fi
      # ( cd $gcmDIR/verification ; ../testreport -clean )
      echo "cvs update of dir $gcmDIR :"
      ( cd $gcmDIR ; $cmdCVS update -P -d ) 2>&1
      retVal=$?
      if test "x$retVal" != x0 ; then
        echo "cvs update on '"`hostname`"' fail (return val=$retVal) => exit"
        exit
      fi
    else
      echo "no dir: $gcmDIR/CVS => try a fresh check-out"
      newCode=2
    fi
  fi
  #- download new code
  if [ $newCode -eq 2 ] ; then
    test -e $gcmDIR && rm -rf $gcmDIR
    echo -n "Downloading the MITgcm code using: $cmdCVS ..."
    $cmdCVS co -P -d $gcmDIR MITgcm > /dev/null 2>&1
    echo "  done"
    for exp2add in $addExp ; do
     echo " add dir: $exp2add (from Contrib:verification_other)"
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
 # #listT='fizhi-cs-32x32x40 fizhi-cs-aqualev20'
 #  export PGI=/srv/software/pgi/pgi-10.9
 #  export PATH="$PATH:$PGI/linux86-64/10.9/bin"
 #  export LM_LICENSE_FILE=$PGI/license.dat
 #fi

#-- run the testreport command:
  echo -n "Running testreport using"	| tee -a $OUTP/output_$tt
  if test "x$OPTFILE" != x ; then
    comm="$comm -of=$OPTFILE"
  fi
  if test $MPI != 0 ; then comm="$comm -MPI $MPI" ; fi
  echo " -norun option ('-nr'):"	| tee -a $OUTP/output_$tt
  comm="$comm -nr"
  if test "x$option" != x ; then comm="$comm $option" ; fi
  echo "  \"eval $comm\""		| tee -a $OUTP/output_$tt
  echo "======================"
  ( cd $gcmDIR/verification
    eval $comm >> $OUTP/output_$tt 2>&1
  )
  sed -n "/^An email /,/^======== End of testreport / p" $OUTP/output_$tt
  echo ""				| tee -a $OUTP/output_$tt

#-- submit PBS script to run
  if test -e $SUB_DIR/${tst2submit}.pbs ; then
    echo " submit PBS bach script '$SUB_DIR/${tst2submit}.pbs'"	| tee -a $OUTP/output_$tt
    $QSUB $SUB_DIR/${tst2submit}.pbs				| tee -a $OUTP/output_$tt
    echo " job '$tst2submit' in queue:"				| tee -a $OUTP/output_$tt
    $QSTAT -a | grep $USER | grep $tst2submit			| tee -a $OUTP/output_$tt
  else
    echo " no PBS script '$SUB_DIR/${tst2submit}.pbs' to submit"| tee -a $OUTP/output_$tt
    continue
  fi

#-- also test restart (test 2+2=4)
  if test $tt != $typ
  then
    echo "testing restart using:"	| tee -a $OUTP/output_$tt
    comm="../tools/do_tst_2+2 -o $dName -a jmc@mitgcm.org"
    if test $MPI = 0 ; then
      echo "  \"$comm\""		| tee -a $OUTP/output_$tt
      echo "======================"
      $comm >> $OUTP/output_$tt 2>&1
    else
      echo "  \"$comm -mpi\""		| tee -a $OUTP/output_$tt
      echo "======================"
      $comm -mpi >> $OUTP/output_$tt 2>&1
    fi
    echo ; cat tst_2+2_out.txt
    echo
  fi
#--reset special setting:
  export OMP_NUM_THREADS=1

done
