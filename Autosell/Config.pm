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
      coinmins   => {} # min sell amounts for coins(optional, coin => amount)
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
    $log->debug( "Attempting to read config file '$self->{ file }'." );
    my $yaml = YAML::Tiny->new;
    $yaml = YAML::Tiny->read( $self->{ file } ) || $log->error_die("Config file not found!");
    
    $log->debug( "Entering general section." );
    
    # poll time
    my $poll = $yaml->[0]->{ general }->{ 'poll-time' } || undef;
    if ( defined $poll )
    {
      $self->{ poll } = $poll;
      $log->info( "Setting poll time to ${poll}s." );
    }
    else
    {
      $log->warn( "Missing poll-time option! Using default of $self->{ poll }." );
    }
    
    # request delay
    my $request = $yaml->[0]->{ general }->{ 'request-delay' } || undef;
    if ( defined $request )
    {
      $self->{ request } = $request;
      $log->info( "Setting request delay to ${request}s." );
    }
    else
    {
      $log->warn( "Missing request-delay option! Using default of $self->{ request }." );
    }
    
    # target currency
    my $target = lc( $yaml->[0]->{ general }->{ 'target' } ) || undef;
    if ( defined $target )
    {
      if ( $target =~ /^(btc|ltc|doge)$/ )
      {
        $self->{ target } = $target;
        $log->info( "Setting target currency to " . uc( $target ) . "." );
      }
      else
      {
        $log->warn( "Unsupported target currency(${target})! Using default of " . uc( $self->{ target } ) . "." );
      }
    }
    else
    {
      $log->warn( "Missing target currency! Using default of " . uc( $self->{ target } ) . "." );
    }
    
    # API keys
    $log->debug( "Entering apikeys section." );
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
    $log->debug( "Entering coins section." );
    foreach my $coin ( keys % { $yaml->[0]->{ coins } } )
    {
      my $min = $yaml->[0]->{ coins }->{ $coin } || undef;
      
      if ( defined $min )
      {
        my $coinUC = uc $coin;
        $log->info( "Setting minimum $coinUC sell amount to $min $coinUC." );
        $self->{ coinmins }->{ $coin } = $min;
      }
    }
  }
  
  1;
