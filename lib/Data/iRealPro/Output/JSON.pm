#! perl

# Data::iRealPro::Output::JSON -- parse iRealPro data and produce JSON

# Author          : Johan Vromans
# Created On      : Fri Jan 15 19:15:00 2016
# Last Modified By: Johan Vromans
# Last Modified On: Tue Oct  4 12:47:40 2016
# Update Count    : 1083
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use Carp;
use utf8;

package Data::iRealPro::Output::JSON;

use parent qw( Data::iRealPro::Output::Base );

our $VERSION = "1.00";

use JSON::PP;

sub process {
    my ( $self, $u, $options ) = @_;

    $self->{output} ||= $options->{output} || "__new__.json";

    my $json = JSON::PP->new->utf8(1)->pretty->indent->canonical;
    $json->allow_blessed->convert_blessed;
    *UNIVERSAL::TO_JSON = sub {
	my $b_obj = B::svref_2object( $_[0] );
	return    $b_obj->isa('B::HV') ? { %{ $_[0] } }
	  : $b_obj->isa('B::AV') ? [ @{ $_[0] } ]
	    : undef
	      ;
    };

    # Process the song(s).
    my @goners = qw( variant debug a2 data raw_tokens cells );
    for my $item ( $u, $u->{playlist} ) {
	delete( $item->{$_} ) for @goners;
    }
    my $songix;
    foreach my $song ( @{ $u->{playlist}->{songs} } ) {
	$songix++;
	warn( sprintf("Song %3d: %s\n", $songix, $song->{title}) )
	  if $self->{verbose};
	$song->tokens;
	delete( $song->{$_} ) for @goners;
    }
    if ( ref( $self->{output} ) ) {
	${ $self->{output} } = $json->encode($u);
    }
    else {
	open( my $fd, ">:utf8", $self->{output} )
	  or die( "Cannot create ", $self->{output}, " [$!]\n" );
	$fd->print( $json->encode($u) );
	$fd->close;
    }
}

1;
