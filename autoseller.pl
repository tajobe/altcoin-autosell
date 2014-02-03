#!/usr/bin/perl

use Data::Dumper;
use Getopt::Long; # command-line options
use warnings;
use strict;

# dependencies
require Log::Log4perl; # logging

# our modules
use Autosell::API::CoinEx; # CoinEx API
use Autosell::Config qw( load ); # our config loader

my $config = undef;
my $configFile = undef;

Log::Log4perl->init( "log.conf" );
my $log = Log::Log4perl->get_logger( "autoseller" );
$log->info;
$log->info( "Autoseller started." );

GetOptions(
                            "usage|help|h|u"                         => \&usage ,
                            "config|file|configfile|cfg:s" => \$configFile );

# init and load config
$config = Autosell::Config->new( $configFile );
$config->load();

# load exchanges
my $exchanges = [];
for my $exchange ( keys % { $config->{ apikeys } } )
{
    # decide what exchange we have a pair for
    if ( lc( $exchange ) eq 'coinex' )
    {
        push(@$exchanges, Autosell::API::CoinEx->new(
          $exchange , $config->{ apikeys }->{ $exchange }->{ key } , $config->{ apikeys }->{ $exchange }->{ secret } ) );
        
        $log->info( "Monitoring $exchange." );
    }
    else
    {
        $log->error( "Unsupported exchange: $exchange" );
    }
}

# error check, shouldn't ever happen as config checks for this
$log->error_die( "No exchanges configured!" ) unless ( @$exchanges );

# attempt to grab currencies from first exchange
my $currencies = $exchanges->[0]->currencies( @ { $config->{ excludes } } );

# attempt to grab markets from first exchange
my $markets = $exchanges->[0]->markets( $config->{ target } , $currencies );

$log->debug( "Found " . keys( % { $currencies } ) . " relevant currencies and " . keys( % { $markets } ) . " markets for them." );

# check balances
my $balances = $exchanges->[0]->balances( keys % { $currencies } );
$log->info( "Balances:" );
foreach my $currencyID ( keys % { $balances } )
{
    $log->info( sprintf( "%20s %s" , sprintf( "%.8f" , $balances->{ $currencyID } ) , $currencies->{ $currencyID } ) );
}

####################################################################################################
# usage
# 
# Print script usage
####################################################################################################
sub usage
{
    print "\n" .
          "$0\n" .
          "Autosell coins on an exchange\n" .
          "\n" .
          "Options:\n" .
          "    -usage: Prints usage\n" .
          "    -config=<filename>: Config file(optional)\n" .
          "\n" .
          "Usage:\n" .
          "    ./$0\n" .
          "    ./$0 -usage\n" .
          "    ./$0 -config=<filename>\n" .
          "\n";
}
