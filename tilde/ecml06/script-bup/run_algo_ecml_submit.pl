#!/usr/bin/perl

use Cwd;

require "../../script/foil-util.pl";

get_dataset_info();

$algo = $ARGV[0];
$remove = $ARGV[1];
$tilde_phb = 0;

$lookahead = 0;
$exlal = 0;

if ($algo =~ /^tilde-l([0-9]+)$/) {
	$lookahead = $1;
	run_tilde($lookahead);
	exit(0);
} elsif ($algo =~ /^tilde-el([0-9]+)$/) {
	$exlal = $1;
	run_tilde($lookahead);
	exit(0);
} elsif ($algo =~ /^tilde-phb([0-9\.]+)$/) {
	$tilde_phb = $1;
	run_tilde($lookahead);
	exit(0);	
} elsif ($algo eq "aleph") {
	run_aleph();
	exit(0);
} else {
	die "Unknown algo: $algo";
}

sub do_remove {
	# notify that i'm done
	if (-f $remove) {
		system("rm $remove");
	}
}

sub run_tilde {
	my($lh) = @_;
	$app = get_foil_name();
	$mc = get_mincases();
	$conf = get_confidence();
	system("mkdir -p $algo");
	for ($i = get_first_fold(); $i <= get_last_fold(); $i++) {
		
		$dtime = get_dtime();
		open(LOG, ">>../../LOG.txt");
		print LOG "[$dtime]" . cwd() . "\n";
		print LOG "fold: $i app: $app lh: $lh exlh: $exlal mc: $mc phb: $tilde_phb\n";
		close(LOG);
		
		print STDERR "Application: " . $app . "\n";
		$odir = "t-$exlal-$lh-$i";
		$cmd = "perl ../../script/" . get_concat_script() . " $i | perl ../../script/foil2tilde.pl $app $lh $odir $tilde_phb $mc $exlal $conf " . get_lroot();
		system($cmd);
		chdir("$odir");
		# Run ACE
		# Currently this is commented out to only generate the dataset
		# system("$ENV{HOME}/ACE/ACE");
		chdir("..");
		
		# Copy results
		# system("mv $odir/tilde/$app.uL1 $algo/$algo-fold$i.out");
		# system("mv $odir/tilde/$app.timers $algo/$algo-fold$i.timers");	
		# system("mv $odir/memory.txt $algo/$algo-fold$i.memory");
		# system("perl ../../script/filter_testpred.pl < $odir/tilde/$app.predictions.testing > $algo/$algo-fold$i.testpred");

		# Comment out the next line to generate all FOLDS!
		exit(0);
		
		# Remove created files
		# Note: comment this out if you don't want the dataset to be removed after the run
		# system("rm -rf $odir");
	}
	do_remove();
}
