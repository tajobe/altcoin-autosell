package Autosell::API::CoinEx;

use parent 'Autosell::API::Exchange';

use Exporter;
use POSIX qw( pow );
use warnings;
use strict;

# dependencies
use Digest::SHA qw( hmac_sha512_hex ); # HMAC-SHA512 signing
use JSON qw( decode_json ); # JSON decode
use Try::Tiny; # error handling

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
#  name: name of exchange
#  key: API key for exchange
#  secret: API secret
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
#  currencies: arrayref*(!) of currencies to look up(by ID)
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
        my $response = $self->_request( 'balances' , 1 );
        foreach my $currency ( @$response )
        {
            $balances->{ $currency->{ currency_id } } = $currency->{ amount } / pow( 10 , 8 ) # (balances are returned as ints(mult by 10^8))
                if ( $currency->{ amount } > 0 );
        }
        
        return $balances;
    }
    catch
    {
    	$log->error( "Error: $_" );
    	$log->error_die( "Unable to get balances from $self->{ name }!" );
    };
}

####################################################################################################
# Get all available currencies on exchange
# 
# Params:
#  excludes: array of coins to exclude(by name)
# 
# Returns hashref of currency ID => name
####################################################################################################
sub currencies
{
    my $self = shift;
    my @tempExcludes = shift;
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
    	$log->error( "Error: $_" );
    	$log->error_die( "Unable to get currencies from $self->{ name }!" );
    };
}

####################################################################################################
# Get available markets for included coins to target currency
# 
# Params:
#  target: target currency(name)
#  currencies: hashref of coins(ID=>name) to fetch trade pairs for(by ID)
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
    $log->error_die( "Could not find target currency '$target' in currencies!" ) unless ( $targetID );
    
    # build currency ID => market ID hash of markets
    $log->debug( "Querying $self->{ name } for applicable markets..." );
    try
    {
        my $markets = {};
        my $response = $self->_request( 'trade_pairs' );
        foreach my $market ( @$response )
        {
            $markets->{ $market->{ currency_id } } = $market->{ id }
                if ( exists $currencies->{ $market->{ currency_id } } && $market->{ market_id } == $targetID );
        }
        
        return $markets;
    }
    catch
    {
    	$log->error( "Error: $_" );
    	$log->error_die( "Unable to get markets from $self->{ name }!" );
    };
}

####################################################################################################
# Send API request
# 
# Params:
#  call: Method/API call (http://URL/call)
#  private: private(1) or public(0) call
#  post: hashref of post data(optional)
# 
# Returns response
####################################################################################################
sub _request
{
    my $self = shift;
    my $call = shift;
    my $private = shift || 0;
    my $post = shift || undef;
    
    # set API keys/sign data if private, undef them if not
    if ( $private )
    {
        $self->{ ua }->default_header( 'API-Key' => $self->{ key } , 'API-Sign' => hmac_sha512_hex( $post || '' , $self->{ secret } ) ); # signed data
    }
    else
    {
        $self->{ ua }->default_header( 'API-Key' => undef , 'API-Sign' => undef ); # not signed data
    }
    
    # form request
    my $method = ( defined $post ) ? 'POST' : 'GET';
    my $request = undef;
    $post = encode_json $post if ( defined $post );
    $request = HTTP::Request->new( $method , $self->{ url } . $call , $self->{ ua }->default_headers , $post);
    
    # perform request and get response
    my $response = $self->{ ua }->request( $request );
    
    # success
    if ( $response->is_success )
    {
    	my $json = decode_json( $response->decoded_content );
    	
    	# ensure we got data we care about
    	unless ( $json->{ $call } )
    	{
            $log->error( "$self->{ name } error on request: '$self->{ url }$call'." );
            $log->error( "Invalid response! Bad data." );
    		die "Invalid response! Bad data.";
    	}
    	return $json->{ $call }
    }
    else
    {
    	$log->error( "$self->{ name } error on request: '$self->{ url }$call'." );
    	$log->error( $response->error_as_HTML );
    	die "Request error!"; # error out
    }
}

1;