#! perl

# Data::iRealPro::Input -- parse iRealPro data

# Author          : Johan Vromans
# Created On      : Tue Sep  6 16:09:10 2016
# Last Modified By: Johan Vromans
# Last Modified On: Tue Mar  7 11:25:23 2017
# Update Count    : 76
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use Carp;
use utf8;

package Data::iRealPro::Input;

our $VERSION = "1.05";

use Data::iRealPro::URI;
use Data::iRealPro::Input::Text;
use Encode qw ( decode_utf8 );
use File::Basename ();

sub new {
    my ( $pkg, $options ) = @_;

    my $self = bless( { variant => "irealpro" }, $pkg );

    for ( qw( trace debug verbose output variant transpose
	      neatify select suppress-upbeat suppress-text
	      musescore override-alt condense ) ) {
	$self->{$_} = $options->{$_} if exists $options->{$_};
    }

    for ( qw( playlist catalog ) ) {
	$self->{$_} = decode_utf8($options->{$_}) if exists $options->{$_};
    }

    return $self;
}

sub parsefile {
    my ( $self, $file ) = @_;

    open( my $fd, '<:utf8', $file ) or die("$file: $!\n");
    my $data = do { local $/; <$fd> };
    my $u = $self->parsedata($data);
    $u->{playlist}->{name} = $self->{playlist} if $self->{playlist};
    return $u;
}

sub parsefiles {
    my ( $self, @files ) = @_;

    my $all;
    foreach my $file ( @files ) {
	warn("Parsing: $file...\n") if $self->{verbose};
	unless ( $self->{playlist} ) {
	    my @p = File::Basename::fileparse( $file,  qr/\.[^.]*/ );
	    $self->{playlist} = $p[0];
	}
	my $u = $self->parsefile($file);
	unless ( $all ) {
	    $all = $u;
	}
	else {
	    $all->{playlist}->add_songs( $u->{playlist}->songs );
	}
    }

    $all->{playlist}->{name} = $self->{playlist} if $self->{playlist};
    $self->apply_selection($all);
}

sub parsedata {
    my ( $self, $data ) = @_;

    my $all;
    if ( eval { $data->[0] } ) {
	foreach my $d ( @$data ) {
	    my $u = $self->parsedata($d);
	    if ( $all ) {
		$all->{playlist}->add_songs( $u->{playlist}->songs );
	    }
	    else {
		$all = $u;
		$all->{playlist}->{name} ||= "NoName";
	    }
	}
	$all->{playlist}->{name} = $self->{playlist} if $self->{playlist};
	$self->apply_selection($all);
    }

    else {
	if ( $data =~ /^Song( \d+)?:/ ) {
	    $all = Data::iRealPro::Input::Text::encode( $self, $data );
	}
	elsif ( $data =~ /^(?:<\?xml.*?>\s*)?<!doctype\s+score-partwise\s+/i ) {
	    require Data::iRealPro::Input::MusicXML;
	    $all = Data::iRealPro::Input::MusicXML::encode( $self, $data );
	}
	else {
	    # Extract URL.
	    $data =~ s;^.*?(irealb(?:ook)?://.*?)(?:$|\").*;$1;s;
	    $data = "irealbook://" . $data
	      unless $data =~ m;^(irealb(?:ook)?://.*?);;

	    $all = Data::iRealPro::URI->new( data => $data,
					     debug => $self->{debug} );
	}
    }

    $all->{playlist}->{name} = $self->{playlist} if $self->{playlist};
    return $all;
}

# Since input can be collected from different sources in spearate calls,
# we need to apply a selection manually.

sub apply_selection {
    my ( $self, $u ) = @_;

    my $i = $self->{select};
    return $u unless $i;

    if ( $i > 0 && $i <= @{ $u->{playlist}->songs } ) {
	$u->{playlist}->{songs} =
	  [ $u->{playlist}->songs->[$i-1] ];
	$u->{playlist}->{songs}->[0]->{songindex} = $i;
	$u->{playlist}->{name} = "";
    }
    else {
	Carp::croak("Invalid value in select");
    }
    return $u;
}

1;
