#!/usr/bin/perl

package Autosell::Config;

use warnings;
use strict;
use Exporter;

use YAML::Tiny qw( LoadFile ); # parse yaml

# exporting
our @ISA = qw( Exporter );
our @EXPORT_OK = qw( load ); # explicit export

# logger
my $log = undef;

####################################################################################################
# Initialize config
# 
# Params:
#  file: Name+path of config file
#
# Returns self
####################################################################################################
sub new
{
    my $class = shift;
    my $self =
    {
        file       => shift || 'config.yml', # config filename;
        log        => $log, # logger
        poll       => 300, # seconds between polls(default 5 mins)
        request    => 15, # request delay in seconds
        target     => 'btc', # target/cashout currency
        apikeys    => {}, # hash of exchange to API key/secret pair
        coinmins   => {}, # min sell amounts for coins(optional, coin => amount)
        excludes   => [] # array of coins to exclude from autosell
    };
  
    $log = Log::Log4perl->get_logger( __PACKAGE__ . '::' . $class );
    bless ( $self , $class );
    return $self;
}

####################################################################################################
# Load config file
####################################################################################################
sub load
{
    my $self = shift || undef;
    
    # need self
    unless ( defined $self )
    {
        $log->error( "Static reference not allowed!" );
        return;
    }
    
    # read config file
    $log->debug( "Attempting to read config file '$self->{ file }'..." );
    my $yaml = YAML::Tiny->new;
    $yaml = YAML::Tiny->read( $self->{ file } ) || $log->error_die("Config file not found!");
    
    $log->debug( "Loading general settings..." );
    
    # poll time
    $self->loadGeneralSetting( $yaml , 'poll-time' , 'poll' , '^\d+$' );
    
    # request delay
    $self->loadGeneralSetting( $yaml , 'request-delay' , 'request' , '^\d+$' );
    
    # target currency
    $self->loadGeneralSetting( $yaml , 'target' , 'target' , '^(btc|ltc|doge)$' );
    
    # API keys
    $log->debug( "Loading API keys..." );
    my $pairfound = 0;
    foreach my $exchange ( keys % { $yaml->[0]->{ apikeys } } )
    {
        $pairfound = 1; # found pair unless proven otherwise
        
        my $key = $yaml->[0]->{ apikeys }->{ $exchange }->{ key } || ($pairfound = 0);
        my $secret = $yaml->[0]->{ apikeys }->{ $exchange }->{ secret } || ($pairfound = 0);
        
        if ( $pairfound )
        {
            $self->{ apikeys }->{ $exchange }->{ key } = $key;
            $self->{ apikeys }->{ $exchange }->{ secret } = $secret;
            $log->info( "API key pair found for exchange '$exchange'." );
        }
    }
    
    # ensure we read at least one set of API keys
    $log->error_die("No API keys configured!") unless ( $pairfound );
    
    # Coin minimum sell amounts
    $log->debug( "Checking for minimum sell amounts..." );
    foreach my $coin ( keys % { $yaml->[0]->{ coinmins } } )
    {
        my $min = $yaml->[0]->{ coinmins }->{ $coin } || undef;
        
        if ( defined $min )
        {
            my $coinUC = uc $coin;
            $log->info( "Setting minimum $coinUC sell amount to $min $coinUC." );
            $self->{ coinmins }->{ $coin } = $min;
        }
    }
    
    # excludes
    $log->debug( "Checking for excluded coins..." );
    for my $coin ( @ { $yaml->[0]->{ excludes } } )
    {
        push( @ { $self->{ excludes } } , lc( $coin ) );
        $log->info( "Excluding " . uc( $coin ) . " from auto-sell." );
    }
}

####################################################################################################
# Load setting from the general section
# 
# Params:
#  yaml: YAML::Tiny object for reading config
#  config: key of setting to load from config
#  setting: Which setting to populate with what's loaded from config
#  matches: Optional matching string
#
####################################################################################################
sub loadGeneralSetting
{
    my $self = shift;
    my $yaml = shift;
    my $config = shift;
    my $setting = shift;
    my $matches = shift || '';
    
    my $value = lc( $yaml->[0]->{ general }->{ $config } ) || undef;
    if ( defined $value )
    {
        if ( $value =~ /$matches/ )
        {
            $self->{ $setting } = $value;
            $log->info( "Setting $config to " . uc( $value ) . "." );
        }
        else
        {
            $log->warn( "Unsupported ${config} value(${value})! Using default of " . uc( $self->{ $setting } ) . "." );
        }
    }
    else
    {
        $log->warn( "Missing $config option! Using default of " . uc( $self->{ $setting } ) . "." );
    }
}

1;
