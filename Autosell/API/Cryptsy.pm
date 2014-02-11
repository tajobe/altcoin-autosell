package Autosell::API::Cryptsy;

use parent 'Autosell::API::Exchange';

use Exporter;
use List::Util qw( max );
use warnings;
use strict;
use Switch;

# dependencies
use Data::URIEncode qw( complex_to_query ); # encode hash for POSTing
use Digest::SHA qw( hmac_sha512_hex ); # HMAC-SHA512 signing
use JSON qw( decode_json ); # JSON encode/decode
use Try::Tiny; # error handling

# logger
my $log;

####################################################################################################
# Initialize Exchange
# 
# Params:
#   name: name of exchange
#   key: API key for exchange
#   secret: API secret
#
# Returns self
####################################################################################################
sub new
{
    my $class = shift;
    my $self = {};
    bless($self, $class);
    $self->_init( @_ );
    return $self;
}

####################################################################################################
# Initialize Exchange
# 
# Params:
#   name: name of exchange
#   key: API key for exchange
#   secret: API secret
#
####################################################################################################
sub _init
{
    my $self = shift;
    $self->SUPER::_init( @_ );
    
    $self->{ url } = 'https://api.cryptsy.com/api'; # API URL
    
    # set headers
    $self->{ ua }->default_header(
        'Content-type' => 'application/x-www-form-urlencode',
        'Accept' => 'application/json',
        'User-Agent' => 'altcoin-autoseller-perl',
        'Key' => $self->{ key } );
    
    $log = Log::Log4perl->get_logger( __PACKAGE__ );
}

####################################################################################################
# Retrieve balances of tracked currencies
# 
# Params:
#   currencies: arrayref*(!) of currencies to look up(by ID)
# 
# Returns hash of currency ID => balance
####################################################################################################
sub balances
{
    die "Not implemented."
}

####################################################################################################
# Get all available currencies on exchange
# 
# Params:
#   excludes: array of coins to exclude(by name)
# 
# Returns hash of currency ID => name
####################################################################################################
sub currencies
{
    my $self = shift;
    my @tempExcludes = @_;
    my %excludes;
    @excludes{ @tempExcludes }=();
    
    # build hashref of currencies
    $log->debug( "Querying $self->{ name } for currencies..." );
    try
    {
        my $currencies = {};
        my $response = $self->_request( 'getmarkets' );
        foreach my $currency ( @$response )
        {
            $currencies->{ $currency->{ marketid } } = $currency->{ 'primary_currency_code' }
                unless ( exists $excludes{ uc( $currency->{ name } ) }  );
        }
        
        return $currencies;
    }
    catch
    {
        $log->error_die( "Unable to get currencies from $self->{ name }!" );
    };
}

####################################################################################################
# Get available markets for included coins to target currency
# 
# Params:
#   target: target currency(name)
#   currencies: hashref of coins(ID=>name) to fetch trade pairs for(by ID)
# 
# Returns hashref of currency ID => trade pair ID where market is for given target
####################################################################################################
sub markets
{
    die "Not implemented.";
}

####################################################################################################
# Get price based on a price strategy
#
# Params:
#   market: trade pair ID
#   strategy: price strategy(match-buy, match-sell, undercut-sell)
#
# Returns market price from given strategy
####################################################################################################
sub getPrice
{
    die "Not implemented.";
}

####################################################################################################
# Submit a sell order
#
# Params:
#   market: trade pair ID
#   amount: amount of currency to sell
#   strategy: sell strategy(match-buy, match-sell, undercut-sell)
#
# Returns hashref of order
####################################################################################################
sub sellOrder
{
    die "Not implemented.";
}

####################################################################################################
# Send API request
# 
# Params:
#   method: Method/API call relative to API URL(http://URL/call)
#   post: hashref of POST data(optional)
# 
# Returns JSON response return data
####################################################################################################
sub _request
{
    my $self = shift;
    my $method = shift;
    my $post = shift || {};
    
    # add required POST data
    $post->{ method } = $method; # API method
    $post->{ nonce } = time; # ever increasing nonce var

    # encode data
    my $postData = complex_to_query $post;

    $log->debug( "POSTing: $postData" );
    
    # sign data
    $self->{ ua }->default_header(
        'Sign' => hmac_sha512_hex( $postData , $self->{ secret } ) ); # signed data

    # form request
    my $request = HTTP::Request->new(
        'POST' , $self->{ url } , $self->{ ua }->default_headers , $postData);
    
    # perform request and get response
    my $response = $self->{ ua }->request( $request );
    
    # successful request
    if ( $response->is_success )
    {
        my $json = decode_json( $response->decoded_content );
        
        # ensure API call was success
        unless ( $json->{ success } )
        {
            $log->error_die( "$self->{ name } error on request: '$self->{ url }': " . $json->{ error } );
        }
        return $json->{ return }
    }
    else
    {
        $log->error_die( "$self->{ name } error on request: '$self->{ url }': " . $response->status_line );
    }
}

1;
