package GMS::Session;

use strict;
use warnings;

use GMS::Config;
use GMS::Schema;

use RPC::Atheme;
use RPC::Atheme::Session;
use GMS::Domain::Accounts;

use TryCatch;

=head1 NAME

GMS::Session - Represents a GMS login session

=head1 DESCRIPTION

A Session represents a GMS login session. Identification and authentication
are provided by Atheme via XML-RPC; authorization is provided in the GMS
database.

=head1 METHODS

=head2 new

    GMS::Session->new($username, $password, $controlsession);

Connects to Atheme using the specified username and password, and returns a
GMS::Session object for the login session.

=cut

sub new {
    my ($class, $user, $pass, $controlsession, %config) = @_;

    $class = ref $class || $class;

    my $self = {
        __conf => \%config,
        _user => $user,
        _control_session => $controlsession,
    };

    my $config = GMS::Config->atheme;

    $self->{_source} = "GMS:$user";
    $self->{_source} .= "(" . $config{source} . ")" if $config{source};


    $self->{_rpcsession} = RPC::Atheme::Session->new(
        $config->{hostname},
        $config->{port},
        $config->{service},
        { persistent => $config{persistent} },
    );

    $self->{_rpcsession}->login($user, $pass, $self->{_source});

    $self->{_authcookie} = $self->{_rpcsession}->authcookie;

    $self->{_db} = GMS::Schema->do_connect;

    my $accounts = GMS::Domain::Accounts->new (
        $controlsession,
        $self->{_db}
    );

    my $account = undef;

    try {
        $account = $accounts->find_by_name ( $user );
    } catch (GMS::Exception $e) {
        die $e;
    } catch (RPC::Atheme::Error $e) {
        die $e;
    }
    if(!$account->verified) {
        die RPC::Atheme::Error->new(RPC::Atheme::Error::notverified, "$user has not completed registration verification");
    }

    $self->{_account} = $account;

    bless $self, $class;
}

=head2 account

Returns a L<GMS::Schema::Result::Account> referring to the GMS account used for
this login session.

=cut

sub account {
    my ($self) = @_;
    return $self->{_account};
}

=head2 authcookie

Returns an authcookie that can be used to communicate with Atheme as the user.

=cut

sub authcookie {
    my ($self) = @_;
    return $self->{_authcookie};
}

1;
