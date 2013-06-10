#!/usr/bin/perl

use strict;
use warnings;

use Test::Most;
use Test::MockModule;

use lib qw(t/lib);

use GMSTest::Common;
use GMSTest::Database;

my $schema = need_database 'new_db';

my $cloakchange = $schema->resultset('CloakChange')->find({ 'id' => 1 });
my $user = $schema->resultset('Account')->find ({ 'accountname' => 'account0' });
my $admin = $schema->resultset('Account')->find({ 'accountname' => 'admin' });

is $schema->resultset('CloakChange')->search_offered->count, 25;
is $schema->resultset('CloakChange')->search_pending->count, 50;

my $mock = new Test::MockModule('GMS::Atheme::Client');

$mock->mock ( 'cloak', sub {
        return 1;
    });

ok $cloakchange->accept ( $user );
$cloakchange->discard_changes;

is $schema->resultset('CloakChange')->search_offered->count, 25, 'An older cloak request is overwritten';
is $schema->resultset('CloakChange')->search_pending->count, 51, 'Cloaks pending staff approval increase';

ok $cloakchange->approve ( undef, $admin );

is $schema->resultset('CloakChange')->search_offered->count, 25, 'Cloaks pending user approval still the same';
is $schema->resultset('CloakChange')->search_pending->count, 50, 'Cloaks pending staff aproval decrease';

$cloakchange = $schema->resultset('CloakChange')->find({ 'id' => 2 });

ok $cloakchange->accept($user);
ok $cloakchange->reject($admin);

$mock->mock ( 'new', sub {
    die RPC::Atheme::Error->new(1, 'Test error');
});

$mock->unmock ('cloak');

$cloakchange = $schema->resultset('CloakChange')->find({ 'id' => 3 });
$cloakchange->accept ( $user );

$cloakchange->approve ( undef, $admin );
$cloakchange->discard_changes;

ok $cloakchange->active_change->status->is_error, "Status is changed to error";

done_testing;