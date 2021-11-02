$c->{plugins}{'Export::ThumbnailInfo'}{params}{disable} = 0;
$c->{on_generate_thumbnails} = sub
{
    my ($session, $doc) = @_;
    my $eprint = $doc->parent;
    my $dir  = $session->get_repository->config( 'variables_path' ) . '/thumbs';
    my $id   = $eprint->value( 'eprintid' );
    # log function call
    my $logfile = $dir . '/on_generate_thumbnails.log';
    if ( open( my $fha, '>>', $logfile ) )
    {
        print $fha sprintf "%s on_generate_thumbnails called for eprint ID: %d\n", scalar localtime, $id;
        close( $fha );
    }
    my $file = "$dir/$id.json";
    if ( -e $file )
    {
        if ( open( my $fha, '>>', $logfile ) )
        {
            print $fha sprintf "JSON cache deleted for eprint ID: %d\n", $id;
            close( $fha );
        }
        unlink $file;
    }
}