
sub get_dtime {
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());
	$mon += 1;
	$year += 1900;
	return "$hour:$min $mday/$mon/$year";
}

sub get_count {
	my ($file, $search) = @_;
	my ($line) = `grep \"$search\" $file | wc`;
	if ($line =~ /^\s*([0-9]+)/) {
		return $1;
	} else {
		return -1;
	}
}

sub cat_file {
	my ($file) = @_;
	open(IN, "$file") || die "Can't open $file";
	while ($line = <IN>) {
		chomp($line);
		if (!($line =~ /^\s*$/)) {
			print "$line\n";
		}
	}
	close(IN);
}

sub cat_file_file {
	my ($file) = @_;
	open(IN, "$file") || die "Can't open $file";
	while ($line = <IN>) {
		chomp($line);
		if (!($line =~ /^\s*$/)) {
			print OUT "$line\n";
		}
	}
	close(IN);
}

sub cat_prolog {
	my ($fname, $cls) = @_;
	open(IN, "$fname") || die "Can't open $fname";
	while ($line = <IN>) {
		chomp($line);
		if ($line =~ /^[^\(]+\(([^\)]+)\)\.\s*$/) {
			$args = $1;
			if ($cls eq "") {
				print "$args\n";
			} else {
				print "$args: $cls\n";
			}
		} elsif (!($line =~ /^\s*$/)) {
			die "Error in line: '$line'";
		}
	}
	close(IN);
}

sub cat_prolog_test {
	my ($fname, $id, $posext, $negext) = @_;
	cat_prolog($fname . $id . $posext, "+");
	cat_prolog($fname . $id . $negext, "-");
	print ".\n";
}

sub cat_prolog_file {
	my ($fname, $cls) = @_;
	open(IN, "$fname") || die "Can't open $fname";
	while ($line = <IN>) {
		chomp($line);
		if ($line =~ /^[^\(]+\(([^\)]+)\)\.\s*$/) {
			$args = $1;
			if ($cls eq "") {
				print OUT "$args\n";
			} else {
				print OUT "$args: $cls\n";
			}
		} elsif (!($line =~ /^\s*$/)) {
			die "Error in line: '$line'";
		}
	}
	close(IN);
}

sub cat_prolog_test_file {
	my ($fname, $id, $posext, $negext, $out) = @_;
	open(OUT, ">$out") || die "Can't create $out";
	cat_prolog_file($fname . $id . $posext, "+");
	cat_prolog_file($fname . $id . $negext, "-");
	print OUT ".\n";
	close(OUT);
}

sub cat_prolog_train {
	my ($fname, $id, $fmin, $fmax, $posext, $negext) = @_;
	for ($crfold = $fmin; $crfold <= $fmax; $crfold++) {
		if ($crfold != $id) {
			cat_prolog($fname . $id . $posext, "");
		}
	}
	print ";\n";
	for ($crfold = $fmin; $crfold <= $fmax; $crfold++) {
		if ($crfold != $id) {
			cat_prolog($fname . $id . $negext, "");
		}
	}
	print ".\n";
}

sub cat_foil_train {
	my ($fname, $id, $fmin, $fmax, $ext) = @_;
	my (@POS) = ();
	my (@NEG) = ();
	print STDERR "Creating training set for fold $id: ";
	for ($crfold = $fmin; $crfold <= $fmax; $crfold++) {
		if ($crfold != $id) {
			my ($name) = $fname . $crfold . $ext;
			print STDERR " $crfold";
			open(IN, $name) || die "Can't open $name";
			while ($line = <IN>) {
				chomp($line);
				if ($line =~ /^([^\:]+)\:\s*([\+\-])$/) {
					if ($2 eq "+") {
						$POS[$#POS+1] = $1;
					} elsif ($2 eq "-") {
						$NEG[$#NEG+1] = $1;
					} else {
						die "Illegal class: '$2'";
					}
				} elsif ($line =~ /^\.$/) {
					# ok
				} elsif (!($line =~ /^\s*$/)) {
					die "Error '$line'";
				}
			}
			close(IN);
		}
	}
	print STDERR "\n";
	foreach $line (@POS) {
		print "$line\n";
	}
	print ";\n";
	foreach $line (@NEG) {
		print "$line\n";
	}
	print ".\n";
}

sub get_dataset_info {
	open(IN, ".INFO") || die "Can't open .INFO file";
	$fold_from = 0; $fold_to = 0; $fold_nb = 0;
	$test_prefix = ""; $concat_prefix = ""; $prolog_name = "";
	$foil_name = ""; $foil_key = ""; $foil_lroot = "";
	$tasks = "default"; $create_sc = ""; $mincases = 2;
	$conf = "none";
	while ($line = <IN>) {
		chomp($line);
		if ($line =~ /^folds\:\s*([0-9]+)\-([0-9]+)\s*$/) {
			$fold_from = $1;
			$fold_to = $2;
			$fold_nb = $fold_to - $fold_from + 1;
		} elsif ($line =~ /^test\-prefix\:\s*([^\s]+)\s*$/) {
			$test_prefix = $1;
		} elsif ($line =~ /^concat\:\s*([^\s]+)\s*$/) {
			$concat_script = $1;
		} elsif ($line =~ /^prolog\:\s*([^\s]+)\s*$/) {
			$prolog_name = $1;
		} elsif ($line =~ /^foil\:\s*([^\s]+)\s*$/) {
			$foil_name = $1;
		} elsif ($line =~ /^key\:\s*([^\s]+)\s*$/) {
			$foil_key = $1;
		} elsif ($line =~ /^lroot\:\s*([^\s]+)\s*$/) {
			$foil_lroot = $1;
		} elsif ($line =~ /^tasks\:\s*(.+)\s*$/) {
			$tasks = $1;
		} elsif ($line =~ /^create\:\s*(.+)\s*$/) {
			$create_sc = $1;
		} elsif ($line =~ /^mincases\:\s*(.+)\s*$/) {
			$mincases = $1;
		} elsif ($line =~ /^conf\:\s*(.+)\s*$/) {
			$conf = $1;
		}
	}
	close(IN);
}

sub m_system {
	my ($str) = @_;
	print "Calling: '$str'\n";
	system($str);
}

sub create_folds {
	my ($prefix, $crfold, $suffix) = @_;
	my ($result) = "";
	my ($mfold);
	for ($mfold = get_first_fold(); $mfold <= get_last_fold(); $mfold++) {
		if ($mfold != $crfold) {
			$result = $result . " " . $prefix . $mfold . $suffix;
		}
	}
	return $result;
}

sub get_tasks() {
	return $tasks;
}

sub get_create() {
	return $create_sc;
}

sub get_nb_folds() {
	return $fold_nb;
}

sub get_first_fold() {
	return $fold_from;
}

sub get_last_fold() {
	return $fold_to;
}

sub get_test_prefix() {
	return $test_prefix;
}

sub get_concat_script() {
	return $concat_script;
}

sub get_prolog_name() {
	return $prolog_name;
}

sub get_foil_name() {
	return $foil_name;
}

sub get_key() {
	return $foil_key;
}

sub get_lroot() {
	return $foil_lroot;
}

sub get_mincases() {
	return $mincases;
}

sub get_confidence() {
	return $conf;
}

return 1;
