
These are the daily MITgcm testing scripts used by Ed Hill on the
"cg01" head node.  The reslts are automatically fed (by email using
the mpack program) into the MITgcm web site at:

  http://mitgcm.org/testing.html

and the scripts have the following pecularities:

  - many paths are hard-coded


The files are:

  cg01_crontab		   result of "crontab -l > itrda_crontab"
    cg01_g77_test_mpi	    \
    cg01_intel_test_mpi      +=> MPI test scripts for each compiler
    cg01_pgi_test_mpi	    /

