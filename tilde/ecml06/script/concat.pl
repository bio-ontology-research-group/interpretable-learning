
require "../../script/foil-util.pl";

get_dataset_info();

$fold = $ARGV[0];
if ($fold eq "") {
	$fold = 0;
}

$app = get_foil_name();
$key = get_key();

cat_file("../foil/$app-c.foil");
print "\n";
# train set
print "$app($key)\n";
cat_foil_train("../foil/folds/test", $fold, get_first_fold(), get_last_fold(), ".txt");
if (-f "../foil/$app-b.foil.gz") {
	system("gunzip -c ../foil/$app-b.foil.gz");
} else {
	cat_file("../foil/$app-b.foil");
}
print "\n";
# test set
if ($fold != -1) {
	print "$app\n";
	print STDERR "Adding test set: test$fold.txt\n";
	cat_file("../foil/folds/test$fold.txt");
}

