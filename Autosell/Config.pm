package Autosell::Config;

use Exporter;
use warnings;
use strict;

# depencencies
use YAML::Tiny qw( LoadFile ); # parse yaml

# exporting
our @ISA = qw( Exporter );
our @EXPORT_OK = qw( load ); # explicit export

# logger
my $log;

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
        file        => shift || 'config.yml', # config filename;
        log         => $log, # logger
        poll        => 300, # seconds between polls(default 5 mins)
        request     => 5, # request delay in seconds
        strategy    => 'match-buy', # sell strategy
        target      => 'BTC', # target/cashout currency
        apikeys     => {}, # hash of exchange to API key/secret pair
        coinmins    => {}, # min sell amounts for coins(optional, coin => amount)
        excludes    => [] # array of coins to exclude from autosell
    };
    
    $log = Log::Log4perl->get_logger( __PACKAGE__ );
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
    $self->_loadGeneralSetting( $yaml , 'poll-time' , 'poll' , '^\d+$' );
    
    # request delay
    $self->_loadGeneralSetting( $yaml , 'request-delay' , 'request' , '^\d+$' );
    
    # sell strategy
    $self->_loadGeneralSetting(
        $yaml , 'strategy' , 'strategy' , '^(match-buy|match-sell|undercut)$' );
    
    # target currency
    $self->_loadGeneralSetting( $yaml , 'target' , 'target' , '^(BTC|LTC|DOGE)$' );
    
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
            $coin = uc $coin;
            $log->info( "Setting minimum $coin sell amount to $min $coin." );
            $self->{ coinmins }->{ $coin } = $min;
        }
    }
    
    # excludes
    $log->debug( "Checking for excluded coins..." );
    for my $coin ( @ { $yaml->[0]->{ excludes } } )
    {
        $coin = uc $coin;
        
        # add exclude unless it's our target.
        # we need that later and won't/can't trade it anyway(EG no such thing as a btc_btc market)
        push( @ { $self->{ excludes } } , $coin ) unless ( $coin eq $self->{ target } );
        
        $log->info( "Excluding $coin from auto-sell." );
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
sub _loadGeneralSetting
{
    my $self = shift;
    my $yaml = shift;
    my $config = shift;
    my $setting = shift;
    my $matches = shift || '';
    
    my $value = uc( $yaml->[0]->{ general }->{ $config } ) || undef;
    if ( defined $value )
    {
        if ( $value =~ /$matches/i )
        {
            $self->{ $setting } = $value;
            $log->info( "Setting $config to $value." );
        }
        else
        {
            $log->warn(
                "Unsupported ${config} value(${value})! Using default of $self->{ $setting }." );
        }
    }
    else
    {
        $log->warn( "Missing $config option! Using default of $self->{ $setting }." );
    }
}

1;
