This repository contains shell scripts for running and collecting daily regression
tests for [MITgcm](https://mitgcm.org/), [code](https://github.com/MITgcm/MITgcm)

 1. shell and batch scripts to run regression tests in `run_tests/`
 2. shell scripts to collect in one place resgression test output
    and update test results [table](https://mitgcm.org/testing-summary/)
    in `collect_tests/`

Note: Regression test set-up are not stored in this repository but instead
directly in the main MITgcm repos,
under [verification](https://github.com/MITgcm/MITgcm/tree/master/verification),
using `testreport` run-script,
with few additional tests from [verifiaction_other](https://github.com/MITgcm/verification_other).

History:
2024-12-06 : This git repos was assembled from two CVS repository pieces,
 [test_scripts](http://wwwcvs.mitgcm.org/viewvc/MITgcm/MITgcm_contrib/test_scripts/)
 for `run_tests/` directory
 and from [scripts](http://wwwcvs.mitgcm.org/viewvc/MITgcm/mitgcm.org/scripts/)
 for `collect_tests/` directory.

