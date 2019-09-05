
@DATA = ("mutab0", "mutaace1", "financial", "sisya", "sisyb", "uwcse", "yeast", "canc", "bongard4");

# Remove next line to generate all datasets!
@DATA = ("mutab0");

$algo = "tilde";

foreach $dset (@DATA) {
	chdir("$dset/results");
	submit("perl ../../script/run_algo_ecml_submit.pl $algo-l0");
	chdir("../../");
}

# foreach $dset (@DATA) {
# 	chdir("$dset/results");
# 	submit("perl ../../script/run_algo_ecml_submit.pl $algo-el1");
# 	chdir("../../");
# }
# 
# foreach $dset (@DATA) {
# 	chdir("$dset/results");
# 	submit("perl ../../script/run_algo_ecml_submit.pl $algo-el2");
# 	chdir("../../");
# }
#
# foreach $dset (@DATA) {
# 	chdir("$dset/results");
# 	submit("perl ../../script/run_algo_ecml_submit.pl $algo-phb1b");
# 	chdir("../../");
# }

sub submit {
	my($arg) = @_;
	system("$arg");
}
