package EnsEMBL::Web::Command::Help::SendEmail;

## Sends the contents of the helpdesk contact form (after checking for spam posting)

use strict;
use warnings;

# use EnsEMBL::Web::Filter::Spam;
use EnsEMBL::Web::Mailer;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self = shift;
  my $object = $self->object;
  my $url;

  if ($object->param('submit') eq 'Back') {
    my $param = {
      name    => $object->param('name'),
      address => $object->param('address'),
      subject => $object->param('subject'),
      message => $object->param('message')
    };
    
    $url = $self->url('/Help/Contact', $param);
  } else {
    my $spam;

    # Check honeypot fields first
    #will prob need a list of these blacklisted addresses, but do this for now to fix Vega spam
    $spam = 1 if $object->param('address') eq 'neverdiespike@hanmail.net';

    if ($object->param('honeypot_1') || $object->param('honeypot_2')) {
      $spam = 1;
    }  else {
      # Check the user's input for spam _before_ we start adding all our crap!
#     my $filter = new EnsEMBL::Web::Filter::Spam;
#     $spam = $filter->check($object->param('message'), 1);
    }

    if (!$spam) {
      my @mail_attributes;
      
      my $species_defs = $object->species_defs;
      my $subject      = ($object->param('subject') || $species_defs->ENSEMBL_SITETYPE . ' Helpdesk') . ' - ' . $species_defs->ENSEMBL_SERVERNAME;
      my @T            = localtime;
      my $date         = sprintf '%04d-%02d-%02d %02d:%02d:%02d', $T[5]+1900, $T[4]+1, $T[3], $T[2], $T[1], $T[0];
      my $url          = $species_defs->ENSEMBL_BASE_URL;
      
      $url = undef if $url =~ m#Help/SendEmail#; # Compensate for auto-filling of _referer
      
      push @mail_attributes, (
        [ 'Date',        $date ],
        [ 'Name',        $object->param('name') ],
        [ 'Referer',     $url || '-none-' ],
        [ 'Last Search', $object->param('string')||'-none-' ],
        [ 'User agent',  $ENV{'HTTP_USER_AGENT'} ]
      );
      
      my $message = 'Support question from ' . $species_defs->ENSEMBL_SERVERNAME . "\n\n";
      $message .= join "\n", map { sprintf '%-16.16s %s', "$_->[0]:", $_->[1] } @mail_attributes;
      $message .= "\n\nComments:\n\n" . $object->param('message') . "\n\n";

      my $mailer = new EnsEMBL::Web::Mailer({
        mail_server => 'localhost',
        from        => $object->param('address'),
        to          => $species_defs->ENSEMBL_HELPDESK_EMAIL,
        subject     => $subject,
        message     => $message
      });
      
      $mailer->send({ spam_check => 0 });
    }

    $url = $self->url('/Help/EmailSent');
  }

  $self->ajax_redirect($url);
}

1;
