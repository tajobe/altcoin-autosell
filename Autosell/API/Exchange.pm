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
#   name: name of exchange
#   key: API key for exchange
#   secret: API secret
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
# See implementation for params and return data spec
####################################################################################################
sub _request
{
    die "Not implemented!";
}

1;
