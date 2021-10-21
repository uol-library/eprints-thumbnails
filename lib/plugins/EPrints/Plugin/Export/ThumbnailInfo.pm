package EPrints::Plugin::Export::ThumbnailInfo;

use EPrints::Plugin::Export::TextFile;
use Image::ExifTool;
use JSON;

@ISA = ( "EPrints::Plugin::Export::TextFile" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my( $self ) = $class->SUPER::new( %opts );

	$self->{name}     = 'Thumbnail Information';
	$self->{accept}   = [ 'dataobj/*' ];
	$self->{visible}  = 'all';
	$self->{suffix}   = '.json';
	$self->{mimetype} = 'application/json; charset=utf-8';

	return $self;
}

sub output_dataobj
{
	my( $plugin, $eprint ) = @_;

	my $repo = $plugin->repository;
	my $id   = $eprint->uri;

	my $data = {
		'eprintid' => $eprint->value( 'eprintid' ),
		'emuid'    => $eprint->value( 'emu_id' ),
		'title'    => $eprint->value( 'title' ),
		'uri'      => $eprint->uri,
		'items'    => [],
	};

	my @docs = $eprint->get_all_documents;

	my @canvases;
	for( my $i = 0; $i < scalar @docs; $i++ )
	{
		my $doc = $docs[$i];
		my @rels;
		my $relation;
		my $filetype;
		if ( $doc->get_value( 'format' ) eq 'audio' )
		{
			$relation = 'isaudio_mp3ThumbnailVersionOf';
		}
		else
		{
			# get all relations
			$relation = undef;
		}

		my $related = $doc->search_related( $relation );
		if ( $related->count > 0 )
		{
			$related->map( sub {
				my( $session, $dataset, $eprintdoc, $rels ) = @_;
				my $thumb = {
					'url'    => $eprintdoc->get_url(),
					'format' => $eprintdoc->value( 'mime_type' ),
				};
				push @$rels, $thumb;

			}, \@rels );
		}
		push @canvases, {
			'url'    => $doc->get_url(),
			'format' => $doc->get_value( 'mime_type' ),
			'thumbs' => \@rels
		};
	}

	$data->{items} = \@canvases;

	return JSON->new->pretty(1)->encode( $data );
}

1;
