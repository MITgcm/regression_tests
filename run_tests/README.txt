
The directories here contain shell scripts used to automate testing on
various systems.  The directory names approximately match the machine
or cluster "nicknames" for which they are intended.  For a description
of the machines and the latest testing output, please see:

  http://mitgcm.org/testing.html

July 28, 2005: Scripts currently used for testing on
   faulks, cg01, itrda (ACESgrid) and columbia
 have been moved to MITgcm/tools/example_scripts/

======================================================================

NOTE: mpack problems

=> was fixed (on Feb 23 & 26, 2008) by using a more recent
 version (1.6-4) of mpack src code.

The mpack utility is used by testreport to mime-encode and email the
testing results back to the mitgcm.org server.  There appears to be a
problem with the mpack utility on some 64-bit systems.  Notably,
emails sent from the following systems:

  SGI Altix
  AMD Opteron

will consistently result in errors ("MIME file corrupted in transit").
Perhaps the mpack utility is not "64-bit clean" and this is
interpreted by munpack as an error during transmission?

