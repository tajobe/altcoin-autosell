package Autosell::API::Exchange;

use Exporter;
use warnings;
use strict;

# depencencies
require HTTP::Request; # HTTP requests
require LWP::UserAgent; # for requests

# exporting
our @ISA = qw( Exporter );
our @EXPORT_OK = qw( currencies ); # explicit export

# logger
my $log;

####################################################################################################
# Initialize Exchange
# 
# Params:
#  name: name of exchange
#  key: API key for exchange
#  secret: API secret
#
####################################################################################################
sub _init
{
    my $self = shift;
    
    $self->{ name } = shift; # exchange name
    $self->{ key } = shift; # API key
    $self->{ secret } = shift; # API secret
    $self->{ ua } = LWP::UserAgent->new; # user agent
    
    $log = Log::Log4perl->get_logger( __PACKAGE__ );
    $log->debug( "Exchange $self->{ name } loaded." );
}

####################################################################################################
# Retrieve balances of tracked currencies
# 
# Params:
#  currencies: arrayref*(!) of currencies to look up(by ID)
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
#  excludes: array of coins to exclude(by name)
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
#  target: target currency(name)
#  currencies: hashref of coins(ID=>name) to fetch trade pairs for(by ID)
# 
# Returns hashref of currency ID => trade pair  ID where market is for given target
####################################################################################################
sub markets
{
    die "Not implemented.";
}

####################################################################################################
# Send API request
# 
# Params:
#  call: Method/API call (http://URL/call)
#  method: http method(GET or POST)
#  private: private(1) or public(0) call
#  post: hashref of post data
# 
####################################################################################################
sub _request
{
    die "Not implemented!";
}

1;
