
require "script/foil-util.pl";

@DATA = ("mutab0", "mutaace1", "financial", "sisya", "sisyb", "uwcse", "yeast", "canc", "bongard4");

foreach $dset (@DATA) {
	system("rm -rf $dset/results/t-*");
	system("rm -rf $dset/results/tilde-*");
}
