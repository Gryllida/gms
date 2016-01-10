package GMS::Domain::Account;

use strict;
use warnings;
use Moose;
use GMS::Atheme::Client;

has _dbic_account_row => (
    is      => 'ro',
    isa     => 'DBIx::Class::Row',
    handles => [ qw (contact_changes contact recent_cloak_changes group_changes group_contact_changes user_roles dropped) ],
);

=head1 PACKAGE

GMS::Domain::Account

=head1 DESCRIPTION

Represents an Atheme account. Contains the
account's name and uid.

=cut

=head1 METHODS

=head2 new

Constructor. Takes a uid, an accountname
as well as the Atheme session object
and the database row object of the
account in question and stores the values
in the GMS::Domain::Account object.

=cut

sub new {
    my ($class, $uid, $accountname, $session, $row) = @_;

    my $self = { };

    $self->{_id} = $uid;
    $self->{_accountname} = $accountname;
    $self->{_session} = $session;
    $self->{_dbic_account_row} = $row;

    bless $self, $class;
}

=head2 id

Returns the account's uid.

=cut

sub id {
    my ($self) = @_;

    $self->{_id};
}

=head2 accountname

Returns the accountname.

=cut

sub accountname {
    my ($self) = @_;

    $self->{_accountname};
}

=head2 mark

Return an account's mark.

=cut

sub mark {
    my ($self) = @_;

    my $client = GMS::Atheme::Client->new ($self->{_session});
    return $client->mark ($self->id);
}

=head2 verified

Checks whether the account is verified.

=cut

sub verified {
    my ($self) = @_;

    my $client = GMS::Atheme::Client->new ($self->{_session});
    return $client->verified ($self->id);
}

=head2 is_dropped

Returns if the account is dropped

=cut

sub is_dropped {
    my ($self) = @_;

    return ($self->dropped ? 1 : 0);
}


=head2 TO_JSON

Returns a representative object for the JSON parser.

=cut

sub TO_JSON {
    my ($self) = @_;

    return {
        accountname => $self->accountname,
        id          => $self->id,
        mark        => $self->mark,
    };
}

1;
