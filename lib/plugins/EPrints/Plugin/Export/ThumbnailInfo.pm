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
	my $exiftool = new Image::ExifTool;

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
		my %rels;
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
				my $thumbpos  = $doc->value( 'pos' );
				if ( $doc->get_value( 'format' ) eq 'audio' )
				{
					$rels->{'url'} = $eprintdoc->get_url();
					$rels->{'permalink'}   = $repo->{config}->{https_url} . '/' . $eprint->value( 'eprintid' ) . '/' . $thumbpos . '.hasaudio_mp3ThumbnailVersion/' . $doc->get_value( 'main' );
				}
				else
				{
					(my $thumbname = $eprintdoc->value( 'main' )) =~ s/\.[^.]+$//;
					my $thumbpl   = $repo->{config}->{https_url} . '/' . $eprint->value( 'eprintid' ) . '/' . $thumbpos . '.has' . $thumbname . 'ThumbnailVersion/' . $doc->get_value( 'main' );
					my $relfileobj = $eprintdoc->stored_file( $eprintdoc->get_main );
					my $relfilepath = '' . $relfileobj->get_local_copy;
					my $relinfo = $exiftool->ExtractInfo( $relfilepath, { 'FastScan' => 5 } );
					my $relimginfo = $exiftool->GetInfo('ImageWidth', 'ImageHeight');
					$rels->{$thumbname} = {
						'url'       => $eprintdoc->get_url(),
						'format'    => $eprintdoc->value( 'mime_type' ),
						'name'      => $thumbname,
						'permalink' => $thumbpl,
						'width'     => 200,#$relimginfo->{'ImageWidth'},
						'height'    => 200,#$relimginfo->{'ImageHeight'},
					};
				}
			}, \%rels );
		}
		my $fileobj  = $doc->stored_file( $doc->get_main );
		my $filepath = '' . $fileobj->get_local_copy;
		my $fileinfo = $exiftool->ExtractInfo( $filepath, { 'FastScan' => 5 } );
		if ( $doc->get_value( 'format' ) eq 'audio' ) {
			my $mp3info         = $exiftool->GetInfo( 'Duration#' );
			push @canvases, {
				'url'         => $doc->get_url(),
				'format'      => $doc->get_value( 'mime_type' ),
				'derivatives' => \%rels,
				'duration'    => sprintf( '%d', $mp3info->{'Duration #'} )
			};
		} elsif ($doc->get_value( 'format' ) eq 'image' ) {
			my $imginfo       = $exiftool->GetInfo('ImageWidth', 'ImageHeight');
			push @canvases, {
				'url'         => $doc->get_url(),
				'format'      => $doc->get_value( 'mime_type' ),
				'derivatives' => \%rels
				'width'       => 200,#$imginfo->{'ImageWidth'},
				'height'      => 200,#$imginfo->{'ImageHeight'},
			};
		}
	}

	$data->{items} = \@canvases;

	return JSON->new->pretty(1)->encode( $data );
}

1;
