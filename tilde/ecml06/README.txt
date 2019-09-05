
This ZIP file contains the following ILP datasets:

$DNAME{"mutab0"}    = "Muta188";
$DNAME{"mutaace1"}  = "Muta230";
$DNAME{"financial"} = "Financial";
$DNAME{"sisya"}     = "Sisyphus A";
$DNAME{"sisyb"}     = "Sisyphus B";
$DNAME{"uwcse"}     = "UWCSE";
$DNAME{"yeast"}     = "Yeast";
$DNAME{"canc"}      = "Carc";
$DNAME{"bongard4"}  = "Bongard";

These were all used in the paper:

Jan Struyf, Jesse Davis and David Page,  An efficient approximation to lookahead in relational learners. In J. Fürnkranz, T. Scheffer and M. Spiliopoulou, editors, Machine Learning: ECML 2006, 17th European Conference on Machine Learning, Proceedings. Lecture Notes in Artificial Intelligence, volume 4212, pages 775-782, Springer, 2006.

The datasets are stored in Quinlan's FOIL format and each dataset has a given partition into folds.

The data and folds are in the "foil" subdirectory of each dataset directory.

The script directory contains scripts to create ACE versions of these datasets.

These are the most important Perl scripts:

run_all.pl                 : Run experiments on all datasets
run_algo_ecml_submit.pl    : Run one experiment on on dataset (called by run_all.pl)
cleanup-all.pl             : Delete all generated files

concat.pl                  : These scripts convert from FOIL to ACE format
foil-util.pl
foil2tilde.pl

Note: the scripts run_all.pl and run_algo_ecml_submit.pl must be adapted before running experiments.

If you run:

perl scripts/run_all.pl

Then only the first fold for the dataset Muta188 will be generated:

jan@shampoo[ecml06] perl script/run_all.pl
Application: muta-d
Creating training set for fold 0:  1 2 3 4 5 6 7 8 9
Adding test set: test0.txt

This dataset is generated in the directory:

jan@shampoo[ecml06] cd mutab0/results/t-0-0-0/
jan@shampoo[t-0-0-0] ls
total 516K
-rw-r--r-- 1 jan 1.2K Jul 10 10:00 muta-d.bg
-rw-r--r-- 1 jan 504K Jul 10 10:00 muta-d.kb
-rw-r--r-- 1 jan 2.0K Jul 10 10:00 muta-d.s

And ACE can be run on this dataset. Note that this is by default the version without any lookahead, so expect the performance to be poor. To get other settings, adapt run_all.pl.

By changing the definition of @DATA at the top of run_all.pl, you can generate more datasets. Note that generating all folds of all datasets takes almost one gigabyte of space in ACE format because the training sets of the folds highly overlap.

Therefore, I used the script to generate a fold, run ACE, copy the results and delete the fold again.

This can be accomplished by editing the script run_algo_ecml_submit.pl. Instructions for doing so are indicated in the scripts.

To remove all generated files run:

perl scripts/cleanup-all.pl

The file ecml_submit.zip contains all fold-wise results from the above mentioned paper.

Enjoy!

Please feel free to direct questions to Jan Struyf.
