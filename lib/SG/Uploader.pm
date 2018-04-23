package SG::Uploader;

sub from_cgi {
    my $q = pop;
    bless { q => $q }, 'SG::Uploader';
}

sub fh {
    my( $self, $field ) = @_;
    $self->{q}->upload( $field );
}

1;
