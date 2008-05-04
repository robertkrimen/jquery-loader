package JS::jQuery::Loader::Source::Google;

use Moose;
extends qw/JS::jQuery::Loader::Source/;
use JS::jQuery::Loader;
use URI;

has version => qw/is ro required 1 lazy 1/, default => JS::YUI::Loader->LATEST_YUI_VERSION;
#has base => qw/is ro/, default => "http://jqueryjs.googlecode.com/files/jquery-1.2.2.min.js
has base => qw/is ro/, default => "http://jqueryjs.googlecode.com/files/";

sub BUILD {
    my $self = shift;
    my $given = shift;
    my $base = $self->base;
    my $version = $self->version || 0;
    $version = JS::YUI::Loader->LATEST_YUI_VERSION if $version eq 0;
    $base =~ s/%v/$version/g;
    $base =~ s/%%/%/g;
    $base = URI->new("$base") unless blessed $base && $base->isa("URI");
    $self->{base} = $base;
}

override uri => sub {
    my $self = shift;
    my $item = shift;
    my $filter = shift;

    $item = $self->catalog->item($item);
    return $item->path_uri($self->base, $filter);
};

1;

