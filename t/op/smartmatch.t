#!./perl

BEGIN {
    chdir 't';
    @INC = '../lib';
    require './test.pl';
}
use strict;

use Tie::Array;
use Tie::Hash;

# The feature mechanism is tested in t/lib/feature/smartmatch:
# This file tests the semantics of the operator, without worrying
# about feature issues such as scoping etc.

# Predeclare vars used in the tests:
my $deep1 = []; push @$deep1, \$deep1;
my $deep2 = []; push @$deep2, \$deep2;

{my $const = "a constant"; sub a_const () {$const}}

my @nums = (1..10);
tie my @tied_nums, 'Tie::StdArray';
@tied_nums =  (1..10);

my %hash = (foo => 17, bar => 23);
tie my %tied_hash, 'Tie::StdHash';
%tied_hash = %hash;

{
    package Test::Object::NoOverload;
    sub new { bless { key => 1 } }
}

{
    package Test::Object::CopyOverload;
    sub new { bless { key => 1 } }
    use overload '~~' => sub { my %hash = %{ $_[0] }; %hash ~~ $_[1] };
}

{
    package Test::Object::OverloadCodeRef;
    sub new { bless $_[1] }
    use overload '~~' => sub { shift->($_[1]) };
}

our $ov_obj = Test::Object::CopyOverload->new;
our $obj = Test::Object::NoOverload->new;
our $false_obj = Test::Object::OverloadCodeRef->new(sub { 0 });
our $true_obj = Test::Object::OverloadCodeRef->new(sub { 1 });


# Load and run the tests
my @tests = map [chomp and split /\t+/, $_, 3], grep !/^#/ && /\S/, <DATA>;
plan tests => 2 * @tests;

for my $test (@tests) {
    my ($yn, $left, $right) = @$test;

    match_test($yn, $left, $right);
    match_test($yn, $right, $left);
}

sub match_test {
    my ($yn, $left, $right) = @_;

    die "Bad test spec: ($yn, $left, $right)"
	unless $yn eq "" || $yn eq "!" || $yn eq '@';
    
    my $tstr = "$left ~~ $right";
    
    my $res;
    $res = eval $tstr // "";	#/ <- fix syntax colouring

    chomp $@;

    if ( $yn eq '@' ) {
	ok( $@ ne '', sprintf "%s%s: %s", $tstr, $@ ? ( ', $@', $@ ) : ( '', $res ) );
    } else {
	if ( $@ ne '' ) {
	    fail("$tstr, \$\@: $@");
	} else {
	    ok( ($yn eq '!' xor $res), "$tstr: $res");
	}
    }
}



sub foo {}
sub bar {2}
sub gorch {2}
sub fatal {die "fatal sub\n"}

sub a_const() {die "const\n" if @_; "a constant"}
sub b_const() {die "const\n" if @_; "a constant"}

__DATA__
# OBJECT
# - overloaded
	$ov_obj		"key"
	$ov_obj		{"key" => 1}
!	$ov_obj		"foo"
!	$ov_obj		\&foo
@	$ov_obj		\&fatal

# regular object
@	$obj	"key"
@	$obj	{"key" => 1}
@	$obj	"foo"
@	$obj	$obj
@	$obj	sub { 1 }
@	$obj	sub { 0 }
@	$obj	\&foo
@	$obj	\&fatal

# CODE ref against argument
#  - arg is code ref
	\&foo		\&foo
!	\&foo		sub {}
!	\&foo		\&bar
	\&fatal		\&fatal
!	\&foo		\&fatal

# - arg is not code ref
	1	sub{shift}
!	0	sub{shift}
!	undef	sub{shift}
	undef	sub{not shift}
	1	sub{scalar @_}
	[]	\&bar
	{}	\&bar
	qr//	\&bar
!	[]	\&foo
!	{}	\&foo
!	qr//	\&foo
!	undef	\&foo
	undef	\&bar
@	undef	\&fatal
@	1	\&fatal
@	[]	\&fatal
@	"foo"	\&fatal
@	qr//	\&fatal
@	$obj	\&bar
	$ov_obj	\&bar

# - null-prototyped subs
	a_const		"a constant"
	a_const		a_const
	a_const		b_const
	\&a_const	\&a_const
!	\&a_const	\&b_const

# - non-null-prototyped subs
!	\&bar		\&gorch
	bar		gorch
@	fatal		bar

# HASH ref against:
#   - another hash ref
	{}		{}
!	{}		{1 => 2}
	{1 => 2}	{1 => 2}
	{1 => 2}	{1 => 3}
!	{1 => 2}	{2 => 3}
	\%main::	{map {$_ => 'x'} keys %main::}

#  - tied hash ref
	\%hash		\%tied_hash
	\%tied_hash	\%tied_hash

#  - an array ref
	\%::		[keys %main::]
!	\%::		[]
	{"" => 1}	[undef]
	{ foo => 1 }	["foo"]
	{ foo => 1 }	["foo", "bar"]
	\%hash		["foo", "bar"]
	\%hash		["foo"]
!	\%hash		["quux"]
	\%hash		[qw(foo quux)]

#  - a regex
	{foo => 1}	qr/^(fo[ox])$/
!	+{0..100}	qr/[13579]$/

#  - a string
	+{foo => 1, bar => 2}	"foo"
!	+{foo => 1, bar => 2}	"baz"


# ARRAY ref against:
#  - another array ref
	[]			[]
!	[]			[1]
	[["foo"], ["bar"]]	[qr/o/, qr/a/]
	["foo", "bar"]		[qr/o/, qr/a/]
!	["foo", "bar"]		[qr/o/, "foo"]
	$deep1			$deep1
!	$deep1			$deep2

	\@nums			\@tied_nums

#  - a regex
	[qw(foo bar baz quux)]	qr/x/
!	[qw(foo bar baz quux)]	qr/y/

# - a number
	[qw(1foo 2bar)]		2

# - a string
!	[qw(1foo 2bar)]		"2"

# Number against number
	2		2
!	2		3

# Number against string
	2		"2"
	2		"2.0"
!	2		"2bananas"
!	2_3		"2_3"

# Regex against string
	qr/x/		"x"
!	qr/y/		"x"

# Regex against number
	12345		qr/3/


# Test the implicit referencing
	@nums		7
	@nums		\@nums
!	@nums		\\@nums
	@nums		[1..10]
!	@nums		[0..9]

	%hash		"foo"
	%hash		/bar/
	%hash		[qw(bar)]
!	%hash		[qw(a b c)]
	%hash		%hash
	%hash		{%hash}
	%hash		%tied_hash
	%tied_hash	%tied_hash
	%hash		{ foo => 5, bar => 10 }
!	%hash		{ foo => 5, bar => 10, quux => 15 }

	@nums		{  1, '',  2, '' }
	@nums		{  1, '', 12, '' }
!	@nums		{ 11, '', 12, '' }

# UNDEF
!	3		undef
!	1		undef
!	[]		undef
!	{}		undef
!	\%::main	undef
!	[1,2]		undef
!	%hash		undef
!	@nums		undef
!	"foo"		undef
!	""		undef
!	!1		undef
!	\&foo		undef
!	sub { }		undef
