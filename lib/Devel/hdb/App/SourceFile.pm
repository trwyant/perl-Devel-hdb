package Devel::hdb::App::SourceFile;

use strict;
use warnings;

use base 'Devel::hdb::App::Base';

use URI::Escape;

__PACKAGE__->add_route('get', qr{/source/(.+)}, \&sourcefile);
__PACKAGE__->add_route('get', qr{(/source)}, \&loaded_files);

# send back a list.  Each list elt is a list of 2 elements:
# 0: the line of code
# 1: whether that line is breakable
sub sourcefile {
    my($class, $app, $env, $filename) = @_;

    $filename = URI::Escape::uri_unescape($filename);

    my @rv;
    if (my $file = $app->file_source($filename)) {
        no warnings 'uninitialized';  # at program termination, the loaded file data can be undef
        no warnings 'numeric';        # eval-ed "sources" generate "not-numeric" warnings
        @rv = map { [ $_, $_ + 0 ] } @$file;
        shift @rv;  # Get rid of the 0th element

        return [ 200,
                [ 'Content-Type' => 'application/json' ],
                [ $app->encode_json(\@rv) ]
            ];
    } else {
        return [ 404,
                [ 'Content-Type' => 'text/html'],
                [ 'File not found' ] ];
    }
}

sub loaded_files {
    my($class, $app, $env, $base_href) = @_;

    my @files = map { { filename => $_,
                        href => join('/', $base_href, URI::Escape::uri_escape($_)) } }
                $app->loaded_files();
    return [ 200,
            [ 'Content-Type' => 'application/json' ],
            [ $app->encode_json(\@files) ]
        ];
}


1;

=pod

=head1 NAME

Devel::hdb::App::SourceFile - Get Perl source for the running program

=head1 DESCRIPTION

Registers routes for getting the Perl source code for files used by the
debugged program.

=head2 Routes

=over 4

=item /sourcefile

This route requires one parameter 'f' , the filename to get the source for.
It returns a JSON-encoded array of arrays.  The first-level array has one
element for each line in the file.  The second-level elements each have
2 elements.  The first is the Perl source for that line in the file.  The
second element is 0 if the line is not breakable, and true if it is.

=item /loadedfiles

Returns a JSON-encoded array of files names loaded by the debugged program.
This list also contains the files used by the debugger, and the file-like
entities for "eval"ed strings.

=back

=head1 SEE ALSO

Devel::hdb

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2014, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.
