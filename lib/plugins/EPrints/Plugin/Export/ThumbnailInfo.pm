package EPrints::Plugin::Export::ThumbnailInfo;

use EPrints::Plugin::Export::TextFile;
use Data::Dumper;
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

	# Should check here to see if there are any queued thmbnailing events
	# If there are, return JSON error code and message
	#my $thumbnailing_events = $repo->dataset( "event_queue" )->search(
	#	'filters' => [
	#		{
	#			'meta_fields' => [ 'pluginid' ],
	#			'value' => 'Convert::Thumbnails',
	#		}
	#	]
	#);
	#if ( $thumbnailing_events->count > 0 )
	#{
	#	return JSON->new->pretty(1)->encode( { 'code' => '425', 'message' => 'Too Early: thumbnails have not been processed yet' } );
	#}
	
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
				my $thumbname = substr $eprintdoc->value( 'main' ), 0, -4;
				my $thumbpos  = $eprintdoc->value( 'pos' );
				my $thumbpl   = $repo->get_url() . '/' . $thumbpos . '.has' . $thumbname . 'ThumbnailVersion/' . $doc->get_value( 'main' );
				my $thumb = {
					'url'      => $eprintdoc->get_url(),
					'format'   => $eprintdoc->value( 'mime_type' ),
					'position' => $thumbpos,
					'name'     => $thumbname,
					'permalink' => $thumbpl,
				};
				push @$rels, $thumb;

			}, \@rels );
		}
		push @canvases, {
			'url'        => $doc->get_url(),
			'format'     => $doc->get_value( 'mime_type' ),
			'thumbnails' => \@rels
		};
	}

	$data->{items} = \@canvases;

	return JSON->new->pretty(1)->encode( $data );
}

1;
