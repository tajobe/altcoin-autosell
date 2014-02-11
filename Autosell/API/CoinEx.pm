package Autosell::API::CoinEx;

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
    
    $self->{ url } = 'https://coinex.pw/api/v2/'; # API URL
    
    # set headers
    $self->{ ua }->default_header(
        'Content-type' => 'application/json',
        'Accept' => 'application/json',
        'User-Agent' => 'altcoin-autoseller-perl' );
    
    $log = Log::Log4perl->get_logger( __PACKAGE__ );
}

####################################################################################################
# Retrieve non-zero balances of tracked currencies
# 
# Params:
#   currencies: arrayref*(!) of currencies to look up(by ID)
# 
# Returns hash of currency ID => balance
####################################################################################################
sub balances
{
    my ( $self , $currencies ) = @_;
    
    # build hashref of currency ID => balance
    $log->debug( "Querying $self->{ name } for balances..." );
    try
    {
        my $balances = {};
        my $response = $self->_request( 'balances' , 'balances' , 'GET' , 1 );
        foreach my $currency ( @$response )
        {
            $balances->{ $currency->{ currency_id } } = $currency->{ amount }
                if ( $currency->{ amount } > 0 );
        }
        
        return $balances;
    }
    catch
    {
        $log->error_die( "Unable to get balances from $self->{ name }!" );
    };
}

####################################################################################################
# Get all available currencies on exchange
# 
# Params:
#   excludes: array of coins to exclude(by name)
# 
# Returns hashref of currency ID => name
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
        my $response = $self->_request( 'currencies' );
        foreach my $currency ( @$response )
        {
            $currencies->{ $currency->{ id } } = $currency->{ name }
                unless ( exists $excludes{ uc( $currency->{ name } ) } ||
                    $currency->{ name } eq 'SwitchPool-scrypt' || # why are these currencies?
                    $currency->{ name } eq 'SwitchPool-sha256' );
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
    my ( $self , $target , $currencies ) = @_;
    
    # find ID of target currency
    my $targetID = undef;
    foreach my $currency ( keys % { $currencies } )
    {
        $targetID = $currency
            if ( uc( $currencies->{ $currency } ) eq uc( $target ));
    }
    
    # shouldn't happen
    $log->error_die( "Could not find target currency '$target' in currencies!" )
        unless ( $targetID );
    
    # build currency ID => market ID hash of markets
    $log->debug( "Querying $self->{ name } for applicable markets..." );
    try
    {
        my $markets = {};
        my $response = $self->_request( 'trade_pairs' );
        foreach my $market ( @$response )
        {
            $markets->{ $market->{ currency_id } } = $market->{ id }
                if ( exists $currencies->{ $market->{ currency_id } } &&
                    $market->{ market_id } == $targetID );
        }
        
        return $markets;
    }
    catch
    {
        $log->error_die( "Unable to get markets from $self->{ name }!" );
    };
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
    my ( $self , $market , $strategy ) = @_;

    $log->trace(
        "Calculating price of trade pair ID $market on $self->{ name } for $strategy strategy..." );
    try
    {
        my $trades = $self->_request( 'orders?tradePair=' . $market );
        my $price = 0;

        # find appropriate price based on strategy
        foreach my $trade ( @$trades )
        {
            # ignore completed or cancelled trades
            if ( ! ( $trade->{ complete } || $trade->{ cancelled } ) )
            {
                switch ( $strategy )
                {
                    # match highest buy price
                    case 'MATCH-BUY'
                    {
                        $price = $trade->{ rate }
                            if ( $trade->{ bid } && $price < $trade->{ rate } );
                    }
                    # match or undercut lowest sell price
                    case /^(MATCH-SELL|UNDERCUT-SELL)$/i
                    {
                        $price = $trade->{ rate }
                            if ( ! $trade->{ bid } &&
                                ($price > $trade->{ rate } || $price == 0));
                    }
                    else
                    {
                        $log->error( "Unknown price strategy '$strategy'!" );
                    }
                }
            }
        }

        # ensure we got a price
        if ( $price == 0 )
        {
            die "No price found using strategy '$strategy'!";
        }

        # apply undercut if needed
        if ( $strategy =~ /^(UNDERCUT-SELL)$/i )
        {
            $price = $price - max( 1 , int( $price * 0.05 ) );
        }

        $log->trace( "$strategy strategy yielded price $price." );
        
        return $price;
    }
    catch
    {
        $log->error_die( "Unable to get prices from $self->{ name }!" );
    };
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
    my ( $self , $market , $amount , $strategy ) = @_;

    # get price
    my $price = $self->getPrice( $market , $strategy );

    # form order
    my $order =
    {
        'trade_pair_id' => $market ,
        'amount' => $amount,
        'bid' => 0, # sell order
        'rate' => $price
    };
    
    # attempt to create order
    $log->trace(
        "Creating sell order for $amount coins in market $market on $self->{ name } for $price each..." );
    try
    {
        return ( $self->_request(
            'orders' , 'order' , 'POST' , 1 , encode_json( { 'order' => $order } ) ) );
    }
    catch
    {
        $log->error_die( "Unable to create order on $self->{ name }!" );
    };
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
# Returns JSON response(arrayref)
####################################################################################################
sub _request
{
    my $self = shift;
    my $call = shift;
    my $jsonRoot = shift || (split( /[\/?]/ , $call ))[0];
    my $method = shift || 'GET';
    my $private = shift || 0;
    my $post = shift || '';
    
    # set API keys/sign data if private, undef them if not
    if ( $private )
    {
        $self->{ ua }->default_header(
            'API-Key' => $self->{ key } ,
            'API-Sign' => hmac_sha512_hex( $post , $self->{ secret } ) ); # signed data
    }
    else
    {
        $self->{ ua }->default_header( 'API-Key' => undef , 'API-Sign' => undef ); # not signed data
    }

    # form request
    my $URL = $self->{ url } . $call;
    my $request = HTTP::Request->new( $method , $URL , $self->{ ua }->default_headers , $post);
    
    # perform request and get response
    my $response = $self->{ ua }->request( $request );
    
    # success
    if ( $response->is_success )
    {
        my $json = decode_json( $response->decoded_content );
        
        # ensure we got data we care about
        unless ( $json->{ $jsonRoot } )
        {
            $log->error_die( "$self->{ name } error on request: '$URL': Bad data." );
        }
        return $json->{ $jsonRoot }
    }
    else
    {
        $log->error_die( "$self->{ name } error on request: '$URL': " . $response->status_line );
    }
}

1;
