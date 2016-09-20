#! perl

use strict;
use warnings;
use Carp;

package Data::iRealPro::Playlist;

our $VERSION = "0.03";

use Data::iRealPro::SongData;

sub new {
    my ( $pkg, %args ) = @_;
    my $self = bless { %args }, $pkg;
    $self->parse( $args{data} ) if $args{data};
    $self->{songs} = [ $args{song} ] if $args{song};
    $self->{songs} = $args{songs} if $args{songs};
    delete $self->{data} unless $self->{debug};
    return $self;
}

sub parse {
    my ( $self, $data ) = @_;

    if ( $data =~ s;^irealb(ook)?://;; && !$self->{variant} ) {
	$self->{variant} = $1 ? "irealbook" : "irealpro";
    }

    # Split the playlist into songs.
    my @a = split( '===', $data, -1 );

    if ( @a > 1 ) {		# song===song===song===ThePlaylist
	$self->{name} = pop(@a);
    }
    elsif ( $self->{variant} eq "irealbook" ) {
	my @b = split( '=', $data, -1 );
	@a = ();
	while ( @b >= 6 ) {
	    push( @a, join( "=", splice( @b, 0, 6 ) ) );
	}
	$self->{name} = pop(@b);
	if ( @b ) {
	    Carp::croak( "Incorrect ", $self->{variant}, " format 2 " . scalar(@b) );
	}
    }

    # Process the song(s).
    foreach ( @a ) {
	eval {
	push( @{ $self->{songs} },
	      Data::iRealPro::SongData->new( variant => $self->{variant},
					      data    => $_,
					      debug   => $self->{debug},
					    ) );
        };
	warn("$@: $_\n") if $@;
    }
    return $self;
}

sub export {
    my ( $self, %args ) = @_;

    my $v = $args{variant} || $self->{variant} || "irealpro";
    my $dashes = $v eq "irealbook" ? "=" : "===";

    my $r = join( $dashes,
		  map { $_->export( %args ) } @{ $self->{songs} } );

    $r .= $dashes . $self->{name} if defined $self->{name};

    return $r;
}

1;
