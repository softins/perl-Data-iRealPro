#! perl

# Ease the life of the CPAN testers.
exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.010000;

require 5.010;

use ExtUtils::MakeMaker;

my $master = 'lib/Data/iRealPro.pm';
my $version = MM->parse_version($master);

WriteMakefile
(
 NAME		=> 'Data::iRealPro',
 ABSTRACT_FROM  => $master,
 VERSION	=> "$version",
 AUTHOR	        => 'Johan Vromans <jvromans@squirrel.nl>',

 INSTALLDIRS	=> 'site',
 EXE_FILES	=> [ 'script/irealcvt' ],
 PL_FILES	=> {
		    'script/pp.PL' => [ 'script/irealcvt' ]
		   },

 PREREQ_PM      => {
		    'PDF::API2'    => 2.026,
		    'Font::TTF'    => 1.06,
		    'Data::Struct' => 1.701,
		    'Text::CSV_XS' => 1.19,
		    'JSON::PP'	   => 2.27300,
		    'HTML::Entities' => 3.69,
		    # 'XML::LibXML'  => 2.0120, # assumed
		   },
 BUILD_REQUIRES  => {
		    'Test::More'   => 1.001014,
		   },

 MIN_PERL_VERSION => '5.010000',
 LICENSE => 'perl',
 META_MERGE => {
     'meta-spec' => { version => 2 },
     resources        => {
	 repository   => {
	     type => 'git',
	     url  => 'git://github.com/sciurius/perl-Data-iRealPro',
	     web  => 'https://github.com/sciurius/perl-Data-iRealPro',
         },
     },
 },

);

1;
