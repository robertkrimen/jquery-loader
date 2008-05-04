package JS::jQuery::Loader;

use warnings;
use strict;

=head1 NAME

JS::jQuery::Loader -

=head1 VERSION

Version 0.01

=head1 jQuery VERSION

Version 1.2.3

=cut

our $VERSION = '0.01';

use constant JQUERY_VERSION => "1.2.3";

=head1 SYNOPSIS

=cut

use Moose;
use JS::jQuery::Loader::Carp;

use JS::jQuery::Loader::Template;
use HTML::Declare qw/LINK SCRIPT/;

has template => qw/is ro required 1 lazy 1 isa JS::jQuery::Loader::Template/, default => sub {
    return JS::jQuery::Loader::Template->new
};
has source => qw/is ro required 1 isa JS::jQuery::Loader::Source/;
has cache => qw/is ro isa JS::jQuery::Loader::Cache/;

=head2 JS::jQuery::Loader->new_from_internet( version => <version> )

Return a new JS::jQuery::Loader object configured to serve/fetch the jQuery .js asset from from http://yui.yahooapis.com/<version>

=cut

sub new_from_internet {
    my $class = shift;

    my ($given, $template) = $class->_new_given_template(@_);

    my %source;
    $source{uri} = delete $given->{uri} if exists $given->{uri};
    require JS::jQuery::Loader::Source::Internet;
    my $source = JS::jQuery::Loader::Source::Internet->new(template => $template, %source);

    return $class->_new_finish($given, $source);
}

=head2 JS::jQuery::Loader->new_from_uri( uri => <uri> )

Return a new JS::jQuery::Loader object configured to serve/fetch the jQuery .js asset from an arbitrary uri

As an example, for a base of C<http://example.com/assets>, the C<reset.css> asset should be available as:

    http://example.com/assets/reset.css

=cut

sub new_from_uri {
    my $class = shift;

    my ($given, $template) = $class->_new_given_template(@_);

    my %source;
    $source{uri} = delete $given->{uri} if exists $given->{uri};
    require JS::jQuery::Loader::Source::URI;
    my $source = JS::jQuery::Loader::Source::URI->new(template => $template, %source);

    return $class->_new_finish($given, $source);
}

=head2 JS::jQuery::Loader->new_from_file( file => <file> )

Return a new JS::jQuery::Loader object configured to fetch/serve the jQuery .js asset from an arbitrary file

As an example, for a dir of C<./assets>, the C<reset.css> asset should be available as:

    ./assets/reset.css

=cut

sub new_from_file {
    my $class = shift;

    my ($given, $template) = $class->_new_given_template(@_);

    my %source;
    $source{file} = delete $given->{file} if exists $given->{file};
    $source{file} = (delete $given->{dir}) . "/\%l" if ! exists $source{file} && exists $given->{dir}; # TODO Or wrap in Path::Class::Dir?
    require JS::jQuery::Loader::Source::File;
    my $source = JS::jQuery::Loader::Source::File->new(template => $template, %source);

    return $class->_new_finish($given, $source);
}

=head2 $loader->filter( <filter> )

Set or clear the current filter

Currently, "min" is the only valid filter

Pass C<undef> to clear the filter

These are equivalent:

    $loader->filter_min
    $loader->filter("min")

    $loader->no_filter
    $loader->filter(undef)

=cut

sub filter {
    my $self = shift;
    $self->template->filter(@_);
    $self->cache->recalculate if $self->cache;
    $self->source->recalculate;
}

=head2 $loader->version( <version> )

Set which jQuery version you want to use

This will also change the filename of the jQuery asset (unless the source/cache has been specially configured)

By default, the latest version is used:

    $loader->version("1.2.3");

=cut

sub version {
    my $self = shift;
    $self->template->version(@_);
    $self->cache->recalculate if $self->cache;
    $self->source->recalculate;
}

=head2 filter_min 

Use the .min version of jQuery

=cut

sub filter_min {
    my $self = shift;
    return $self->filter("min");
    return $self;
}

=head2 no_filter 

Disable filtering of included components (do not use the .min version)

=cut

sub no_filter {
    my $self = shift;
    $self->filter("");
    return $self;
}

=head2 uri

Attempt to fetch a L<URI> for jQuery using the current filter setting of the loader (.min, etc.)

If the loader has a cache, then this method will try to fetch from the cache. Otherwise it will use the source.

=cut

sub uri {
    my $self = shift;
    return $self->cache_uri(@_) if $self->cache;
    return $self->source_uri(@_);
}

=head2 file

Attempt to fetch a L<Path::Class::File> for jQuery using the current filter setting of the loader (.min, etc.)

If the loader has a cache, then this method will try to fetch from the cache. Otherwise it will use the source.

=cut

sub file {
    my $self = shift;
    return $self->cache_file(@_) if $self->cache;
    return $self->source_file(@_);
}

=head2 cache_uri

Attempt to fetch a L<URI> for jQuery using the current filter setting of the loader (.min, etc.) from the cache

=cut

sub cache_uri {
    my $self = shift;
    my $name = shift;
    return $self->cache->uri || croak "Unable to get uri from cache ", $self->cache;
}

=head2 cache_file

Attempt to fetch a L<Path::Class::File> for jQuery using the current filter setting of the loader (.min, etc.) from the cache

=cut

sub cache_file {
    my $self = shift;
    my $name = shift;
    return $self->cache->file || croak "Unable to get file for from cache ", $self->cache;
}

=head2 source_uri

Attempt to fetch a L<URI> for jQuery using the current filter setting of the loader (.min, etc.) from the source

=cut

sub source_uri {
    my $self = shift;
    my $name = shift;
    return $self->source->uri || croak "Unable to get uri for from source ", $self->source;
}

=head2 source_file

Attempt to fetch a L<Path::Class::File> for jQuery using the current filter setting of the loader (.min, etc.) from the source

=cut

sub source_file {
    my $self = shift;
    return $self->source->file || croak "Unable to get file for from source ", $self->source;
}

sub _html {
    my $self = shift;
    my $uri = shift;

    return SCRIPT({ type => "text/javascript", src => $uri, _ => "" });
}

=head2 html

Generate and return a string containing HTML describing how to include components. For example, you can use this in the <head> section
of a web page.

If the loader has a cache, then it will attempt to generate URIs from the cache, otherwise it will use the source.

Here is an example:

    <link rel="stylesheet" href="http://example.com/assets/reset.css" type="text/css"/>
    <link rel="stylesheet" href="http://example.com/assets/fonts.css" type="text/css"/>
    <link rel="stylesheet" href="http://example.com/assets/base.css" type="text/css"/>
    <script src="http://example.com/assets/yahoo.js" type="text/javascript"></script>
    <script src="http://example.com/assets/dom.js" type="text/javascript"></script>
    <script src="http://example.com/assets/event.js" type="text/javascript"></script>
    <script src="http://example.com/assets/logger.js" type="text/javascript"></script>
    <script src="http://example.com/assets/yuitest.js" type="text/javascript"></script>

=cut

sub html {
    my $self = shift;
    return $self->_html($self->uri);
}

=head2 source_html

Generate and return a string containing HTML describing how to include components. For example, you can use this in the <head> section
of a web page.

Here is an example:

    <link rel="stylesheet" href="http://example.com/assets/reset.css" type="text/css"/>
    <link rel="stylesheet" href="http://example.com/assets/fonts.css" type="text/css"/>
    <link rel="stylesheet" href="http://example.com/assets/base.css" type="text/css"/>
    <script src="http://example.com/assets/yahoo.js" type="text/javascript"></script>
    <script src="http://example.com/assets/dom.js" type="text/javascript"></script>
    <script src="http://example.com/assets/event.js" type="text/javascript"></script>
    <script src="http://example.com/assets/logger.js" type="text/javascript"></script>
    <script src="http://example.com/assets/yuitest.js" type="text/javascript"></script>

=cut

sub source_html {
    my $self = shift;
    return $self->_html($self->source->uri);
}

sub _new_given {
    my $class = shift;
    return @_ == 1 && ref $_[0] eq "HASH" ? shift : { @_ };
}

sub _new_template {
    my $class = shift;
    my $given = shift;
    my $template = delete $given->{template} || {};
    $template->{version} = delete $given->{version} if defined $given->{version};
    $template->{filter} = delete $given->{filter} if defined $given->{filter};
    $template->{version} ||= JQUERY_VERSION;
    return $given->{template} = $template if blessed $template;
    return $given->{template} = JS::jQuery::Loader::Template->new(%$template);
}

sub _build_cache {
    my $class = shift;
    my $given = shift;
    my $source = shift;

    my (%cache, $cache_class);

    if (ref $given eq "HASH") {
        $cache_class = "JS::jQuery::Loader::Cache::URI";
        my ($uri, $file, $dir) = @$given{qw/uri file dir/};
        %cache = (uri => $uri, file => $file, dir => $dir);
    }
    elsif (ref $given eq "Path::Resource") {
        $cache_class = "JS::jQuery::Loader::Cache::URI";
        %cache = (uri => $given->uri, file => $given->file);
    }
    else {
        $cache_class = "JS::jQuery::Loader::Cache::File";
        %cache = (file => $given);
    }

    eval "require $cache_class;" or die $@;

    return $cache_class->new(source => $source, %cache);
}

sub _new_cache {
    my $class = shift;
    my $given = shift;
    my $source = shift;
    if (my $cache = delete $given->{cache}) {
        $given->{cache} = $class->_build_cache($cache, $source);
    }
}

sub _new_given_template {
    my $class = shift;
    my $given = $class->_new_given(@_);

    my $template = $class->_new_template($given);

    return ($given, $template);
}

sub _new_finish {
    my $class = shift;
    my $given = shift;
    my $source = shift;

    $class->_new_cache($given, $source);

    return $class->new(%$given, source => $source);
}

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-js-jquery-loader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JS-jQuery-Loader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JS::jQuery::Loader


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=JS-jQuery-Loader>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JS-jQuery-Loader>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/JS-jQuery-Loader>

=item * Search CPAN

L<http://search.cpan.org/dist/JS-jQuery-Loader>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of JS::jQuery::Loader
