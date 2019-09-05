
# Script for converting a FOIL .d file to ACE .kb, .bg and .s files

# Application name
$fname = $ARGV[0];

# Use lookahead?
$lh = $ARGV[1];

# Output dir?
$odir = $ARGV[2];

# PHB?
$phb = $ARGV[3];

$mc = $ARGV[4];

$exlh = $ARGV[5];

$conf = $ARGV[6];

if ($mc eq "") {
	$mc = 2;
}
if ($lh eq "") {
	$lh = 0;
}
if ($odir eq "") {
	$odir = "tilde";
}

if ($conf eq "") {
	$conf = "none";
}

if (-f $extra) {
	print "Reading extra settings file: '$extra'\n";
	open(IN, $extra) || die "Can't open $extra";
	while ($line = <IN>) {
		chomp($line);
		if ($line =~ /^relmode\:\s*([^\s]+)\s+(.+)\s*$/) {
			$REL_MODE{$1} = $2;
		} elsif (!($line =~ /^\s*$/)) {
			die "Illegal line '$line', while reading extra settings";
		}
	}
	close(IN);
}

$has_relation = 0;
$key_rel = "";

# read types
while (($done == 0) && ($line = <STDIN>)) {
	chomp($line);
	if ($line =~ /^\s*$/) {
		$done = 1;
	} elsif ($line =~ /^\#{0,1}([^\:]+)\:\s*(.+)\s*\.$/) {
		$type = $1; $vals = $2;
		@theorycte = ();
		@arr = split(/\s*\,\s*/, $vals);
		foreach $val (@arr) {
			if ($val =~ /^\s*\*(.+)\s*$/) {
				push @theorycte, prolog_atom($1);
			}
		}
		$res = join(",", @theorycte);
		if ($res ne "") {
			$THEORY_TYPE{$type} = $res;
		}
		if ($vals eq "continuous") {
			$CONTINUOUS{$type} = 1;
		}
	} else {
		die "Illegal type definition: '$line'";
	}
}

# convert to valid prolog atom
sub prolog_atom {
	my ($prolog_name) = @_;
	$prolog_name = lc($prolog_name);
	if ($prolog_name =~ /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/) {
		# valid floating point number
		return $prolog_name;
	}
	$prolog_name =~ s/\s+/\_/g;
	$prolog_name =~ s/\'+/\_/g;
	$prolog_name =~ s/\-+/\_/g;
	if ($prolog_name =~ /[\[\]\;\+\/\>\<\(\)]/) {
		$prolog_name = "'$prolog_name'";
	} elsif ($prolog_name =~ /^([0-9])/) {
		$prolog_name = "'$prolog_name'";
	}
	$prolog_name =~ s/\-\-+/\_/g;
	return $prolog_name;
}

# convert to valid prolog var
sub prolog_var {
	my ($prolog_name, $idx) = @_;
	$prolog_name = prolog_atom($prolog_name);
	if ($prolog_name =~ /^([a-z])(.*)$/) {
		$first = $1; $rest = $2;
		return uc($first) . $rest . $idx;
	} else {
		return "A$prolog_name" . $idx;
	}
}

# create/clean output directory
system("mkdir -p $odir");
system("rm -rf $odir/*");
chdir("$odir") || die "Failed to create directory '$odir'";

open(KB, ">$fname.kb") || die "Can't create '$fname.kb'";

# read relations
while ($line = <STDIN>) {
	chomp($line);
	# read next relation definition in the file
	if ($line =~ /^(\*{0,1})([^\(]+)\(([^\)]+)\)\s*(.*)$/) {
		# Found relation
		$prefix = $1; $rel_name = $2; $arg_str = $3; $suffix = $4; $is_key = 0;
		if ($has_relation == 0) {
			# Relation providing the example key
			$key_rel = $rel_name;
			$is_key = 1;
		}
		@args = split(/\s*\,\s*/, $arg_str);
		$nb_args = $#args+1; $has_relation = 1;
		$prolog_name = prolog_atom($rel_name);
		if (defined($REL_PROLOG{$rel_name})) {
			die "Relation '$rel_name' occurs twice in input file";
		}
		$REL_NB_ARGS{$rel_name} = $nb_args;
		$REL_PROLOG{$rel_name} = $prolog_name;
		$REL_ARGS{$rel_name} = $arg_str;
		if (defined($REL_MODE{$rel_name})) {
			$REL_SUFFIX{$rel_name} = $REL_MODE{$rel_name};
		} else {
			$REL_SUFFIX{$rel_name} = $suffix;
		}
		# Read tuples of the relation
		$done = 0; $rec_cnt = 0; $cls = "pos";
		while (($done == 0) && ($line = <STDIN>)) {
			chomp($line);
			$rec_cnt++;
			if ($line =~ /^\.\s*$/) {
				$done = 1;
			} elsif ($line =~ /^\;\s*$/) {
				$cls = "neg";
			} else {
				@vals = split(/\s*\,\s*/, $line);
				$nb_vals = $#vals+1;
				if ($nb_vals != $nb_args) {
					die "Incorrect number of arguments for '$relname': found $nb_vals <> $nb_args at record $rec_cnt";
				}
				for ($k = 0; $k < $nb_vals; $k++) {
					$vals[$k] = prolog_atom($vals[$k]);
				}
				$line = join(",", @vals);
				if ($is_key == 0) {
					print KB "$prolog_name($line).\n";
				} else {
					if ($nb_vals > 1) {
						print KB "$prolog_name($vals[0],$cls).\n";
						push @KMAP, $line;
					} else {
						print KB "$prolog_name($line,$cls).\n";
					}
				}
			}
		}
		print KB "\n";
	} elsif ($line eq $key_rel) {
		$done = 0; $rec_cnt = 0;
		$nb_args = $REL_NB_ARGS{$key_rel}; $prolog_name = $REL_PROLOG{$key_rel};
		while (($done == 0) && ($line = <STDIN>)) {
			chomp($line);
			$rec_cnt++;
			if ($line =~ /^\.\s*$/) {
				$done = 1;
			} elsif ($line =~ /^([^\:]+)\:\s*([\+\-])\s*$/) {
				$tuple = $1; $cls = $2;
				@vals = split(/\s*\,\s*/, $tuple);
				$nb_vals = $#vals+1;
				if ($nb_vals != $nb_args) {
					die "Incorrect number of arguments for '$relname': found $nb_vals <> $nb_args at record $rec_cnt";
				}
				for ($k = 0; $k < $nb_vals; $k++) {
					$vals[$k] = prolog_atom($vals[$k]);
				}
				$tuple = join(",", @vals);
				if ($nb_vals > 1) {
					push @KMAP, $tuple;
				}
				if ($cls eq "+") {
					$cls = "pos";
				} elsif ($cls eq "-") {
					$cls = "neg";
				} else {
					die "Illegal class '$cls' in line '$line'";
				}
				print KB "$prolog_name($vals[0],$cls).\n";
				push @testid, $vals[0];
			} elsif (!($line =~ /^\s*$/)) {
				die "Illegal line '$line', while reading test set";
			}
		}
		print KB "\n";
	} elsif (!($line =~ /^\s*$/)) {
		die "illegal line '$line'";
	}
}

# enumerate the test instances
foreach $test (@testid) {
	print KB "testid($test,1).\n";
}

# enumerate the key map
foreach $map (@KMAP) {
	print KB "kmap($map).\n";
}

close(KB);

$nb_kmap = $#KMAP+1;

open(SF, ">$fname.s") || die "Can't create '$fname.s'";

# write out hint
print SF "% Start Tilde with the command 'loofl(tilde,[1])'\n\n";

if ($phb != 0) {
	print SF "load_package(phb).\n\n";
}

# write out predict setting
@args = split(/\s*\,\s*/, $REL_ARGS{$key_rel});
$arg = prolog_atom($args[0]);
print SF "predict($REL_PROLOG{$key_rel}(+$arg,-class)).\n\n";

if ($nb_kmap > 0) {
	print SF "root(($REL_PROLOG{$key_rel}(X,Y), kmap(X";
	for ($i = 1; $i < $#args+1; $i++) {
		print SF ",_";
	}
	print SF "))).\n\n";
}

print SF "tilde_mode(classify).\n";
print SF "classes([pos,neg]).\n";
print SF "max_lookahead($lh).\n";
print SF "discretize(equal_freq).\n";
print SF "report_timings(on).\n";
print SF "use_packs(cf_ilp).\n";
print SF "sampling_strategy(none).\n";
print SF "minimal_cases($mc).\n";
print SF "write_predictions([testing,distribution]).\n";
print SF "m_estimate(m(2)).\n";
print SF "tilde_rst_optimization(no).\n";
print SF "exhaustive_lookahead($exlh).\n";
if ($phb == 0) {
	print SF "query_batch_size(50000).\n\n";
}
if ($conf ne "none") {
	print SF "confidence_level($conf).\n\n";
}

foreach $rel (sort keys %REL_PROLOG) {
	if ($rel ne $key_rel) {
		push @RELATIONS, $rel;
	}
}

# write out types
print SF "typed_language(yes).\n";
foreach $rel (@RELATIONS) {
	$prolog_name = $REL_PROLOG{$rel};
	print SF "type($prolog_name(";
	@args = split(/\s*\,\s*/, $REL_ARGS{$rel});
	$idx = 0;
	foreach $arg (@args) {
		$arg = prolog_atom($arg);
		if ($idx != 0) { print SF ","; }
		print SF "$arg";
		$idx++;
	}
	print SF ")).\n";
}

if ($nb_kmap > 0) {
	# write out predict setting
	@args = split(/\s*\,\s*/, $REL_ARGS{$key_rel});
	print SF "type(kmap(";
	$idx = 0;
	foreach $arg (@args) {
		$arg = prolog_atom($arg);
		if ($idx != 0) { print SF ","; }
		print SF "$arg";
		$idx++;
	}
	print SF ")).\n";
}

foreach $type (sort keys %THEORY_TYPE) {
	$prolog_name = prolog_atom($type);
	print SF "type(eq_$prolog_name($prolog_name,$prolog_name)).\n";
}
foreach $type (sort keys %CONTINUOUS) {
	$prolog_name = prolog_atom($type);
	print SF "type(le_$prolog_name($prolog_name, $prolog_name)).\n";
	print SF "type(gt_$prolog_name($prolog_name, $prolog_name)).\n";
}
print SF "\n";

# write out rmodes
foreach $rel (@RELATIONS) {
	$prolog_name = $REL_PROLOG{$rel};
	foreach $suffix (split(/\//, $REL_SUFFIX{$rel})) {
		print SF "rmode($prolog_name(";
		@args = split(/\s*\,\s*/, $REL_ARGS{$rel});
		$idx = 0;
		foreach $arg (@args) {
			$var = prolog_var($arg, $idx);
			$mode = substr($suffix,$idx,1);
			if ($mode eq "#") { 
				$mode = "+"; 
			} elsif ($mode eq "=") { 
				$mode = "-"; 
				$AUTO_LH{$rel} = 1;
				if ($CONTINUOUS{$arg} == 1) {
					$CONT_NB_MODES{$arg}++;
				}
			} elsif ($mode eq "-") {
				if ($CONTINUOUS{$arg} == 1) {
					$mode = "-";
					$CONT_NB_MODES{$arg}++;
				} else {
					$mode = "+-";
				}
				$AUTO_LH{$rel} = 1;
			}
			if ($idx != 0) { print SF ","; }
			print SF "$mode$var";
			$idx++;
		}
		print SF ")).\n";
	}
}
print SF "\n";

if ($lh > 0) {
	# create auto-lookaheads
	foreach $rel (sort keys %AUTO_LH) {
		$prolog_name = $REL_PROLOG{$rel};
		$suffix = $REL_SUFFIX{$rel};
		print SF "auto_lookahead($prolog_name(";
		@args = split(/\s*\,\s*/, $REL_ARGS{$rel});
		$idx = 0;
		foreach $arg (@args) {
			if ($idx != 0) { print SF ","; }
			print SF prolog_var($arg, $idx);
			$idx++;
		}
		print SF "), [";
		$idx = 0; $cnt = 0;
		foreach $arg (@args) {
			$mode = substr($suffix,$idx,1);
			if (($mode eq "-") || ($mode eq "=")) {
				if ($cnt != 0) { print SF ","; }
				print SF prolog_var($arg, $idx);
				$cnt++;
			}
			$idx++;
		}
		print SF "]).\n";
	}
	print SF "\n";
}

# write out theory constants
$nb_theory = 0;
foreach $type (sort keys %THEORY_TYPE) {
	$prolog_name = prolog_atom($type);
	print SF "rmode(eq_$prolog_name(+X, #[$THEORY_TYPE{$type}])).\n";
	$nb_theory++;
}
if ($nb_theory > 0) { print SF "\n"; }

# write distretization clauses
foreach $type (sort keys %CONTINUOUS) {
	$prolog_name = prolog_atom($type);
	@args = split(/\s*\,\s*/, $REL_ARGS{$key_rel});
	print SF "to_be_discretized(gen_$prolog_name(";
	$idx = 0;
	foreach $arg (@args) {
		$arg = prolog_atom($arg);
		print SF prolog_var($arg, $idx);
		print SF ",";
		$idx++;
	}
	print SF "Y), 5, [Y]).\n";
}

# write numeric comparisons
foreach $type (sort keys %CONTINUOUS) {
	$prolog_name = prolog_atom($type);
	$prefix = "#(C: threshold(gen_$prolog_name(";
	@args = split(/\s*\,\s*/, $REL_ARGS{$key_rel});
	foreach $arg (@args) {
		$prefix = $prefix . "_,";
	}
	$prefix = $prefix . "Y), [Y], C)";
	print SF "rmode($prefix, le_$prolog_name(+X, C))).\n";
	print SF "rmode($prefix, gt_$prolog_name(+X, C))).\n";
}

print SF "\n";

if ($phb != 0) {
	print SF "phb_enable(yes).\n";
	print SF "phb_write_info(on).\n";
	if ($phb == 1) {			
		print SF "phb_always(yes).\n";
		print SF "phb_mode(2).\n";
		print SF "phb_maxdepth(1).\n";
	} elsif ($phb == 2) {
		print SF "phb_always(yes).\n";
		print SF "phb_mode(2).\n";
		print SF "phb_maxdepth(2).\n";
	} elsif ($phb == 3) {
		print SF "phb_always(no).\n";
		print SF "phb_mode(2).\n";
		print SF "phb_maxdepth(1).\n";
	} elsif ($phb == 4) {
		print SF "phb_always(no).\n";
		print SF "phb_mode(1).\n";
		print SF "phb_maxdepth(1).\n";
	}
}
print SF "execute(loofl(tilde,[1])).\n";
print SF "execute(quit).\n";

close(SF);

open(BG, ">$fname.bg") || die "Can't create '$fname.bg'";

foreach $type (sort keys %THEORY_TYPE) {
	$prolog_name = prolog_atom($type);
	print BG "eq_$prolog_name(A, B) :- A == B.\n";
}

foreach $type (sort keys %CONTINUOUS) {
	$prolog_name = prolog_atom($type);
	print BG "le_$prolog_name(A, B) :- A =< B.\n";
}

foreach $type (sort keys %CONTINUOUS) {
	$prolog_name = prolog_atom($type);
	print BG "gt_$prolog_name(A, B) :- A > B.\n";
}

print BG "\n";

%THEORY_ALL = ();
foreach $type (sort keys %THEORY_TYPE) {
	$prolog_name = prolog_atom($type);
	foreach $c (split(/\s*\,\s*/, $THEORY_TYPE{$type})) {
		$THEORY_ALL{$c} = 1;
		print BG "theorycte($type, $c).\n";
	}
}

#foreach $c (sort keys %THEORY_ALL) {
#	print BG "theorycte($c).\n";
#}

print BG "\n";

foreach $type (sort keys %THEORY_TYPE) {
	$prolog_name = prolog_atom($type);
	print BG "phb_ignore(eq_$prolog_name/2).\n";
}

foreach $type (sort keys %CONTINUOUS) {
	$prolog_name = prolog_atom($type);
	print BG "phb_ignore(le_$prolog_name/2).\n";
}

foreach $type (sort keys %CONTINUOUS) {
	$prolog_name = prolog_atom($type);
	print BG "phb_ignore(gt_$prolog_name/2).\n";
}

foreach $type (sort keys %CONTINUOUS) {
	$prolog_name = prolog_atom($type);
	print BG "is_continuous($prolog_name).\n";
}

print BG "\n";

# write constant generators
foreach $type (sort keys %CONTINUOUS) {
	$prolog_name = prolog_atom($type);
	if ($CONT_NB_MODES{$type} > 0) {
		@args = split(/\s*\,\s*/, $REL_ARGS{$key_rel});
		print BG "\ngen_$prolog_name(";
		$idx = 0;
		foreach $arg (@args) {
			$arg = prolog_atom($arg);
			print BG prolog_var($arg, $idx);
			print BG ",";
			$idx++;
		}
		print BG "Y) :-\n";
		if ($CONT_NB_MODES{$type} > 1) {
			print BG "   (\n";
		}
		$nbcalls = 0;
		foreach $rel (@RELATIONS) {
			$prolog_name = $REL_PROLOG{$rel};
			$suffix = $REL_SUFFIX{$rel};
			@args = split(/\s*\,\s*/, $REL_ARGS{$rel});
			$idx = 0;
			foreach $arg (@args) {
				$mode = substr($suffix,$idx,1);
				if ((($mode eq "-") || ($mode eq "=")) && ($CONTINUOUS{$arg} == 1)) {
					if ($nbcalls != 0) { print BG "   ;\n"; }
					print BG "      $prolog_name(";
					$idx2 = 0;
					foreach $arg2 (@args) {
						$mode = substr($suffix,$idx2,1);
						if ($idx2 != 0) { print BG ","; }
						if ($idx2 == $idx) {
							print BG "Y";
						} else {
							$var = prolog_var($arg2, $idx2);
							print BG "$var";
						}
						$idx2++;
					}
					print BG ")\n";
					$nbcalls++;
				}
				$idx++;
			}
		}
		if ($CONT_NB_MODES{$type} > 1) {
			print BG "   )";
		}
		print BG ".\n";
	}
}

close(BG);

foreach $key (keys %REL_MODE) {
	if (!defined($REL_PROLOG{$key})) {
		die "Relation: '$key' not defined in FOIL file";
	}
}

chdir("..");
