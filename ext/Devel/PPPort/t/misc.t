################################################################################
#
#            !!!!!   Do NOT edit this file directly!   !!!!!
#
#            Edit mktests.PL and/or parts/inc/misc instead.
#
#  This file was automatically generated from the definition files in the
#  parts/inc/ subdirectory by mktests.PL. To learn more about how all this
#  works, please read the F<HACKERS> file that came with this distribution.
#
################################################################################

BEGIN {
  if ($ENV{'PERL_CORE'}) {
    chdir 't' if -d 't';
    @INC = ('../lib', '../ext/Devel/PPPort/t') if -d '../lib' && -d '../ext';
    require Config; import Config;
    use vars '%Config';
    if (" $Config{'extensions'} " !~ m[ Devel/PPPort ]) {
      print "1..0 # Skip -- Perl configured without Devel::PPPort module\n";
      exit 0;
    }
  }
  else {
    unshift @INC, 't';
  }

  sub load {
    eval "use Test";
    require 'testutil.pl' if $@;
  }

  if (38) {
    load();
    plan(tests => 38);
  }
}

use Devel::PPPort;
use strict;
$^W = 1;

package Devel::PPPort;
use vars '@ISA';
require DynaLoader;
@ISA = qw(DynaLoader);
bootstrap Devel::PPPort;

package main;

use vars qw($my_sv @my_av %my_hv);

my @s = &Devel::PPPort::newSVpvn();
ok(@s == 5);
ok($s[0], "test");
ok($s[1], "te");
ok($s[2], "");
ok(!defined($s[3]));
ok(!defined($s[4]));

ok(&Devel::PPPort::boolSV(1));
ok(!&Devel::PPPort::boolSV(0));

$_ = "Fred";
ok(&Devel::PPPort::DEFSV(), "Fred");
ok(&Devel::PPPort::UNDERBAR(), "Fred");

if ($] >= 5.009002) {
  eval q{
    my $_ = "Tony";
    ok(&Devel::PPPort::DEFSV(), "Fred");
    ok(&Devel::PPPort::UNDERBAR(), "Tony");
  };
}
else {
  ok(1);
  ok(1);
}

eval { 1 };
ok(!&Devel::PPPort::ERRSV());
eval { cannot_call_this_one() };
ok(&Devel::PPPort::ERRSV());

ok(&Devel::PPPort::gv_stashpvn('Devel::PPPort', 0));
ok(!&Devel::PPPort::gv_stashpvn('does::not::exist', 0));
ok(&Devel::PPPort::gv_stashpvn('does::not::exist', 1));

$my_sv = 1;
ok(&Devel::PPPort::get_sv('my_sv', 0));
ok(!&Devel::PPPort::get_sv('not_my_sv', 0));
ok(&Devel::PPPort::get_sv('not_my_sv', 1));

@my_av = (1);
ok(&Devel::PPPort::get_av('my_av', 0));
ok(!&Devel::PPPort::get_av('not_my_av', 0));
ok(&Devel::PPPort::get_av('not_my_av', 1));

%my_hv = (a=>1);
ok(&Devel::PPPort::get_hv('my_hv', 0));
ok(!&Devel::PPPort::get_hv('not_my_hv', 0));
ok(&Devel::PPPort::get_hv('not_my_hv', 1));

sub my_cv { 1 };
ok(&Devel::PPPort::get_cv('my_cv', 0));
ok(!&Devel::PPPort::get_cv('not_my_cv', 0));
ok(&Devel::PPPort::get_cv('not_my_cv', 1));

ok(Devel::PPPort::dXSTARG(42), 43);
ok(Devel::PPPort::dAXMARK(4711), 4710);

ok(Devel::PPPort::prepush(), 42);

ok(join(':', Devel::PPPort::xsreturn(0)), 'test1');
ok(join(':', Devel::PPPort::xsreturn(1)), 'test1:test2');

ok(Devel::PPPort::PERL_ABS(42), 42);
ok(Devel::PPPort::PERL_ABS(-13), 13);

ok(Devel::PPPort::SVf(42), $] >= 5.004 ? '[42]' : '42');
ok(Devel::PPPort::SVf('abc'), $] >= 5.004 ? '[abc]' : 'abc');
