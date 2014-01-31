#!/usr/bin/perl

  use warnings;
  use strict;

  use JSON qw ( decode_json ); # JSON decode  
  require Log::Log4perl; # logging
  require LWP::UserAgent; # for requests
  use Getopt::Long; # command-line options
  
  # our modules
  use Autosell::Config qw( load ); # our config loader
  
  my $config = undef;
  my $configFile = undef;  

  Log::Log4perl->init( "log.conf" );
  my $log = Log::Log4perl->get_logger( "autoseller" );
  $log->info;
  $log->info( "Autoseller started." );

  GetOptions( "usage|help|h|u"               => \&usage ,
              "config|file|configfile|cfg:s" => \$configFile );
  
  # init and load config
  $config = Autosell::Config->new( $configFile );
  $config->load();

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
