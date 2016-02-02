#!perl

#$change->active_change->changed_by,

use strict;
use warnings;

use DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
   'schema_from_schema_loader';

schema_from_schema_loader({ naming => 'v4' }, sub {
  my $schema = shift;

  my @cloaks = $schema->resultset('CloakChanges')->all();

  foreach my $cloak (@cloaks) {
      if (!$cloak->requestor) {
          my $offer = $cloak->cloak_change_changes->find({
                  status => 'offered',
              });

          next unless $offer;

          $cloak->requestor($offer->changed_by);
          $cloak->update;
      }
  }
});
