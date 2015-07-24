=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Draw::GlyphSet::flat_file;

### Module for drawing features parsed from a non-indexed text file (such as 
### user-uploaded data)

use strict;

use EnsEMBL::Web::File::User;
use EnsEMBL::Web::IOWrapper;
use EnsEMBL::Web::Utils::FormatText qw(add_links);

use EnsEMBL::Draw::Style::Feature;
use EnsEMBL::Draw::Style::Feature::Joined;

use base qw(EnsEMBL::Draw::GlyphSet::Alignment);

sub features {
  my $self         = shift;
  my $container    = $self->{'container'};
  my $species_defs = $self->species_defs;
  my $sub_type     = $self->my_config('sub_type');
  my $format       = $self->my_config('format');
  my $features     = [];

  ## Get the file contents
  my %args = (
              'hub'     => $self->{'config'}->hub,
              'format'  => $format,
              );

  if ($sub_type eq 'url') {
    $args{'file'} = $self->my_config('url');
    $args{'input_drivers'} = ['URL'];
  }
  else {
    $args{'file'} = $self->my_config('file');
    if ($args{'file'} !~ /\//) { ## TmpFile upload
      $args{'prefix'} = 'user_upload';
    }
  }

  my $file  = EnsEMBL::Web::File::User->new(%args);
  my $iow   = EnsEMBL::Web::IOWrapper::open($file);

  if ($iow) {
    ## Parse the file, filtering on the current slice
    $features = $iow->create_tracks($container);
  } else {
    #return $self->errorTrack(sprintf 'Could not read file %s', $self->my_config('caption'));
    warn "!!! ERROR READING FILE ".$file->absolute_read_path;
  }

  return $features;
}

sub render_as_alignment_nolabel {
  my $self = shift;

  ## Defaults
  my $colour_key     = $self->colour_key('default');
  $self->{'my_config'}->set('default_colour', $self->my_colour($colour_key));

  $self->{'my_config'}->set('bumped', 1);
  $self->{'my_config'}->set('same_strand', $self->strand);
  unless ($self->{'my_config'}->get('height')) {
    $self->{'my_config'}->set('height', 8);
  }

  my $subtracks = $self->features;
  my $config    = $self->track_style_config;

  my $key = $self->{'hover_label_class'};
  my $hover_label = $self->{'config'}->{'hover_labels'}{$key};

  foreach (@$subtracks) {
    my $features  = $_->{'features'};
    my $metadata  = $_->{'metadata'};
    my $name      = $metadata->{'name'};
    $self->{'my_config'}->set('caption', $name) if $name;

    ## Add any suitable metadata to track name mouseover menu
    my $extras;
    my $description = $metadata->{'description'};
    if ($description) {
      $description = add_links($description);
      $extras = $description;
    }
    my $url = $metadata->{'url'};
    if ($url) {
      $extras .= sprintf(' For more information, visit <a href="%s">%s</a>', $url, $url);
    }
    $hover_label->{'extra_desc'} = $extras;

    my $style     = EnsEMBL::Draw::Style::Feature::Joined->new($config, $features);
    $self->push($style->create_glyphs);
  }
}

sub href {
}



1;
