#! perl

# Data::iRealPro::Output -- pass data to backends

# Author          : Johan Vromans
# Created On      : Tue Sep  6 16:09:10 2016
# Last Modified By: Johan Vromans
# Last Modified On: Fri Oct  7 09:50:21 2016
# Update Count    : 72
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use Carp;
use utf8;

package Data::iRealPro::Output;

our $VERSION = "1.00";

use Data::iRealPro::Input;
use Encode qw ( decode_utf8 );

sub new {
    my ( $pkg, $options ) = @_;

    my $self = bless( { variant => "irealpro" }, $pkg );
    my $opts;

    $opts->{output} = $options->{output} || "";
    if ( $options->{list}
	 || $opts->{output} =~ /\.txt$/i ) {
	require Data::iRealPro::Output::Text;
	$self->{_backend} = Data::iRealPro::Output::Text::;
	$opts->{output} ||= "-";
    }
    elsif ( $opts->{output} =~ /\.jso?n$/i ) {
	require Data::iRealPro::Output::JSON;
	$self->{_backend} = Data::iRealPro::Output::JSON::;
    }
    elsif ( $options->{split}
	    || $opts->{output} =~ /\.html$/i ) {
	require Data::iRealPro::Output::HTML;
	$self->{_backend} = Data::iRealPro::Output::HTML::;
    }
    else {
	require Data::iRealPro::Output::Imager;
	$self->{_backend} = Data::iRealPro::Output::Imager::;
    }

    for ( @{ $self->{_backend}->options } ) {
	$opts->{$_} = $options->{$_} if exists $options->{$_};
    }

    $self->{options} = $opts;
    return $self;
}

sub processfiles {
    my ( $self, @files ) = @_;
    my $opts = $self->{options};

    my $all = Data::iRealPro::Input->new($opts)->parsefiles(@files);
    $self->{_backend}->new($opts)->process( $all, $opts );
}

1;
