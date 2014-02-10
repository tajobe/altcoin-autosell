package Autosell::API::Cryptsy;

use parent 'Autosell::API::Exchange';

use Exporter;
use List::Util qw( max );
use warnings;
use strict;
use Switch;

# dependencies
use Digest::SHA qw( hmac_sha512_hex ); # HMAC-SHA512 signing
use JSON qw( encode_json decode_json ); # JSON encode/decode
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
        'Content-type' => 'application/json',
        'Accept' => 'application/json',
        'User-Agent' => 'altcoin-autoseller-perl' );
    
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
    die "Not implemented.";
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
#   call: Method/API call relative to API URL(http://URL/call)
#   jsonRoot: root of JSON response data
#   method: http method(GET or POST)
#   private: private(1) or public(0) call
#   post: JSON encoded POST data(optional)
# 
# Returns JSON response
####################################################################################################
sub _request
{
    die "Not implemented!";
}

1;
