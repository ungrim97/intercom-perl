package Intercom::Client::User;

use Moo;
use Carp;
use URI;
use Intercom::Resource::ErrorList;

# Request handler for the client. This differs from the
# other SDK implementations to avoid circular references
has request_handler => (is => 'ro', required => 1);

=head1 NAME

Intercom::Client::User - User Resource class

=head1 SYNOPSIS

    my $users = $client->users->search({email => 'test1@test.com});
    my $user = $users->users->[0];

    $user = $client->users->update({
        id    => $user->id,
        email => 'test2@test.com'
    });

=head1 DESCRIPTION

Core client lib for access to the /user resource in the API

SEE ALSO: L<Users|https://developers.intercom.com/intercom-api-reference/reference#users>

=head2 METHODS

=head3 create (HashRef $user_data) -> Intercom::Resource::User|Intercom::Resource::ErrorList

    my $user = $client->users->create({
        email => 'test@test.com',
        companies => [{
            company_id => 366,
            name => 'test'
        }];
    });

Create a new user with the provided $user_data.

Will return a new instance of a L<Intercom::Resource::User> or an instance of an
L<Intercom::Resource::ErrorList>

SEE ALSO:
    L<Create Users|https://developers.intercom.com/intercom-api-reference/reference#create-or-update-user>

=cut

sub create {
    my ($self, $user_data) = @_;

    return $self->request_handler->post(URI->new('/users'), $user_data);
}

=head3 update (HashRef $user_data) -> Intercom::Resource::User|Intercom::Resource::ErrorList

    my $user = $client->users->update({
        email => 'test@test.com',
        companies => [{
            company_id => 366,
            name => 'test'
        }];
    });

Update an existing user with the provided $user_data. User will be matched by
the value of the 'id', 'email' or 'user_id' fields in the data

Will return a new instance of a L<Intercom::Resource::User> or an instance of an
L<Intercom::Resource::ErrorList>

SEE ALSO:
    L<Update Users|https://developers.intercom.com/intercom-api-reference/reference#create-or-update-user>


=cut

sub update {
    my ($self, $user_data) = @_;

    unless ($user_data->{id} || $user_data->{email} || $user_data->{user_id}) {
        return Intercom::Resource::ErrorList->new(errors => [{
            code => 'parameter_not_found',
            message => 'Update requires one of `id`, `email` or `user_id`'
        }]);
    }

    return $self->create($user_data);
}

=head3 list (Hashref $options) -> Intercom::Resource::UserList|Intercom::Resource::ErrorList

    my $users = $client->users->list({created_since => 365}) # all users in the last year

    do {
        confess 'Error' if $users->type eq 'ErrorList';

        for my $user ($users->users){
            ...
        }
    } while ($users = $users->page->next() )

Retrieve a list of users. By default this will fetch the last 50 created users.
The returned L<Intercom::Resource::UserList> object also contains a L<page object|Intercom::Resource::Page>
which can be used to fetch more users in a paginated fashion

Available options are:

=over

=item *

page - numeric page to retrieve

=item *

per_page - number of users to include per page (default 50, max 60)

=item *

order - Direction to sort the users via the sort value (default desc)

=item *

sort - Field to sort on. Either created_at, last_request_at, signed_up_at or
updated_at. (default created_at)

=item *

created_since - limit results to users that were created in that last number of
days

=back

SEE ALSO: L<List Users|https://developers.intercom.com/intercom-api-reference/v1.1/reference#list-users>

=cut

sub list {
    my ($self, $options) = @_;

    my $uri = URI->new('/users');
    $uri->query_form($options);

    return $self->request_handler->get($uri);
}

=head3 get (Str $id) -> Intercom::Resource::User|Intercom::Resource::ErrorList

    my $user = $client->users->get(1);

Retrieve a user based on their primary intercom ID ($id)

Returns either an instance of an L<Intercom::Resource::User> or an instance of an
L<Intercom::Resource::ErrorList>

SEE ALSO: L<View a User|https://developers.intercom.com/intercom-api-reference/v1.1/reference#view-a-user>

=cut

sub get {
    my ($self, $id) = @_;

    unless ($id) {
        return Intercom::Resource::ErrorList->new(errors => [{
            code => 'parameter_not_found',
            message => 'Get requires an `id` parameter'
        }]);
    }

    return $self->request_handler->get($self->_user_path({id => $id}));
}

=head3 search (HashRef $params) -> Intercom::Resource::UserList|Intercom::Resource::ErrorList

    my $user2 = $client->users->search({email => 'test@test.com'});
    my $user3 = $client->users->search({user_id => '12333'});

Search for users as identified by an email ($params->{email})
or custom user_id ($params->{user_id})

Returns either an instance of an Intercom::Resource::UserList or an instance of
an Intercom::Resource::ErrorList

NOTE: If you search via custom user_id then this will return an instance of Intercom::Resource::User
rather than an UserList

SEE ALSO: L<Search Users|https://developers.intercom.com/intercom-api-reference/v1.1/reference#view-a-user>

=cut

sub search {
    my ($self, $params) = @_;

    unless ($params->{email} || $params->{user_id}) {
        return Intercom::Resource::ErrorList->new(errors => [{
            code => 'parameter_not_found',
            message => 'Search requires one of `email` or `user_id`'
        }]);
    }
    return $self->request_handler->get($self->_user_path($params));
}

=head3 scroll () -> Intercom::Resource::UserList|Intercom::Resource::ErrorList

    my $users = $client->users->scroll() # all users

    do {
        confess 'Error' if $users->type eq 'ErrorList';

        for my $user ($users->users){
            ...
        }
    } while ($users = $users->page->next() )

Efficiently retrieve a list of users. By default this will fetch the last 50
created users. The returned L<Intercom::Resource::UserList> object also contains a
L<page object|Intercom::Resource::Page> which can be used to fetch more users
in a paginated fashion

NOTE: Scrolled user lists can only be paged to the next page. There is no
ability to return to a previous page

SEE ALSO: L<Scroll users|https://developers.intercom.com/intercom-api-reference/v1.1/reference#iterating-over-all-users>

=cut

sub scroll {
    my ($self) = @_;

    return $self->request_handler->get(URI->new('/users/scroll'));
}

=head3 archive (HashRef $params) -> Intercom::Resource::User|Intercom::Resource::ErrorList

    my $user  = $client->users->archive({id => 1});
    my $user2 = $client->users->archive({email => 'test@test.com'});
    my $user3 = $client->users->archive({user_id => '12333'});

Archive a user based on their primary intercom ID ($params->{id})

Alternatively archive a user as identified by their email ($params->{email})
or custom user_id ($params->{user_id})

Returns either an instance of an L<Intercom::Resource::User> or an instance of an
L<Intercom::Resource::ErrorList>

SEE ALSO: L<Archive a User|https://developers.intercom.com/intercom-api-reference/v1.1/reference#archive-a-user>

=cut

sub archive {
    my ($self, $params) = @_;

    unless ($params->{id} || $params->{email} || $params->{user_id}) {
        return Intercom::Resource::ErrorList->new(errors => [{
            code => 'parameter_not_found',
            message => 'Search requires one of `email` or `user_id`'
        }]);
    }
    return $self->request_handler->delete($self->_user_path($params));
}

=head3 permanently_delete (Str $id) -> HashRef|Intercom::Resource::ErrorList

    my $return = $client->users->permanently_delete(1);

Permanently remove a user as identified by their Intercom user id ($id).

Returns either a hashref containing a single id key whose value is the
id of the deleted user.

SEE ALSO: L<Delete a user|https://developers.intercom.com/intercom-api-reference/v1.1/reference#delete-users>

=cut

sub permanently_delete {
    my ($self, $id) = @_;

    return $self->request_handler->post(
        URI->new('/user_delete_requests'),
        {intercom_user_id => $id}
    );
}

sub _user_path {
    my ($self, $params) = @_;

    if (my $id = $params->{id}) {
        return URI->new("/users/$id");
    }

    my $uri = URI->new('/users');
    if (my $email = $params->{email}) {
        $uri->query_form(email => $email);
        return $uri;
    }

    if (my $user_id = $params->{user_id}) {
        $uri->query_form(user_id => $user_id);
        return $uri;
    }

    confess('No [id], [email] or [user_id] provided to identify user');
}

1;
