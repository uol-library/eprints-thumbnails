package EPrints::Plugin::Export::IIIFManifest;

use EPrints::Plugin::Export::TextFile;
use JSON;

@ISA = ( "EPrints::Plugin::Export::TextFile" );

use strict;

sub new
{
	my( $class, %opts ) = @_;

	my( $self ) = $class->SUPER::new( %opts );

	$self->{name}     = "IIIF Manifest";
	$self->{accept}   = [ 'dataobj/*' ];
	$self->{visible}  = "all";
	$self->{suffix}   = ".json";
	$self->{mimetype} = "application/json; charset=utf-8";

	return $self;
}

sub output_dataobj
{
	my( $plugin, $eprint ) = @_;

	my $repo = $plugin->repository;
	my $id   = $eprint->uri;

	my $data = {
		'@context'  => 'http://iiif.io/api/presentation/3/context.json',
		'id'        => $id,
		'type'      => 'Manifest',
		'label'     => { 'en' => [ $eprint->value( 'title' ) ] },
		'summary'   => { 'en' => [ $eprint->value( 'abstract' ) ] },
		'behaviour' => [ 'paged' ],
		'items'     => [],
		'metadata'  => [
			{
				'label' => { 'en' => [ 'Collection' ] },
				'value' => { 'en' => [ $eprint->value( 'collection' ) ] },
			},
			{
				'label' => { 'en' => [ 'Date range' ] },
				'value' => { 'en' => [ $eprint->value( 'date_range' ) ] },
			},
			{
				'label' => { 'en' => [ 'EMu ID' ] },
				'value' => { 'en' => [ $eprint->value( 'emu_id' ) ] },
			},
			{
				'label' => { 'en' => [ 'Physical Identifier' ] },
				'value' => { 'en' => [ $eprint->value( 'physical_identifier' ) ] },
			}
		],
	};

	my @docs = $eprint->get_all_documents;

	my @canvases;
	for( my $i = 0; $i < scalar @docs; $i++ )
	{
		my $doc = $docs[$i];
		my @rels;
		my $relation;
		if ( $doc->get_value( 'format' ) eq 'audio' ) {
			$relation = 'isaudio_mp3ThumbnailVersionOf';
		} elsif ($doc->get_value( 'format' ) eq 'image' ) {
			$relation = 'islightboxThumbnailVersionOf';
		}

		my $related = $doc->search_related( $relation );
		if ( $related->count > 0 )
		{
			$related->map( sub {
				my( $session, $dataset, $eprintdoc, $rels ) = @_;
				my $thumb = {
					'id'     => $eprintdoc->get_url(),
					'type'   => 'Image',
					'format' => $eprintdoc->value( 'mime_type' ),
				};
				push @$rels, $thumb;

			}, \@rels );
		}
		push @canvases, {
			'id'    => $doc->uri,
			'type'  => 'Canvas',
			'label' => $doc->get_value( 'formatdesc' ),
			'items' => [
				{
					'id'        => $doc->uri,
					'type'      => 'Annotation',
					'body'      => {
						'id'     => $doc->get_url(),
						'type'   => 'Image',
						'format' => $doc->get_value( 'mime_type' )
					},
					'thumbnail' => \@rels
				}
			]
		};
	}

	$data->{items} = \@canvases;

	return JSON->new->pretty(1)->encode( $data );
}

1;
