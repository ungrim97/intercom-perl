use lib 't/lib';

use JSON;
use Test::Most tests => 2;
use Test::MockObject;
use Test::Mock::LWP::Dispatch;
use SharedTests::Request;

use Intercom::Client;

SharedTests::Request::all_tests(sub {
    return shift->users->permanently_delete({email => 'test@test.com'});
});

subtest 'permanently_delete user' => sub {
    plan tests => 4;

    my $mock_ua = LWP::UserAgent->new();
    $mock_ua->map(
        sub {
            my ($request) = @_;

            is($request->method, 'POST', 'Request has correct HTTP Verb');
            cmp_deeply(JSON::decode_json($request->content()), {intercom_user_id => 1}, 'Request has correct data');

            return like($request->uri(), qr#/user_delete_requests$#, 'Request has correct URI');
        },
        sub {
            my ($request) = @_;
            my $response = HTTP::Response->new(
                '200',
                'OK',
                [ 'Content-Type' => 'application/json' ],
                JSON::encode_json({id => 1})
            );

            $response->request($request);
            return $response;
        }
    );

    my $client = Intercom::Client->new({
        access_token => 'test',
        ua         => $mock_ua
    });

    my $user = $client->users->permanently_delete(1);

    cmp_deeply($user, {id => 1}, 'ID returned correctly');
};
