altcoin-autosell
================

Cryptocurrency/altcoin autoseller script written in Perl, loosely based on dtbartle/altcoin-autosell.

Requires modules Digest::SHA, HTTP::Request, JSON, Log::Log4perl, LWP::Protocol::https, LWP::UserAgent, Try::Tiny, and YAML::Tiny.  
Install using CPAN:
```shell
cpan Digest::SHA HTTP::Request JSON Log::Log4perl LWP::Protocol::https LWP::UserAgent Try::Tiny YAML::Tiny
```
  
USAGE:
```shell
./autoseller.pl -usage
```
```shell
perl autoseller.pl -usage
```

Example config(included):
```yaml
    ##########
    # General settings
    ##########
    general:
      poll-time: 300    # Amount of time between polls
      request-delay: 15 # Delay when we are going to send a request
      target: BTC       # Target currency(btc/ltc/doge)
    
    ##########
    # Any number of API keys for us to monitor/use
    # 
    # Format:
    # exchange: (coinex)
    #   key: 'API key'
    #   secret: 'API secret'
    ##########
    apikeys:
      coinex:           # exchange the keys are for(determines what API we need to use)
        key: ''         # API key
        secret: ''      # API secret
    
    ##########
    # Min sell amounts for any number of coins (OPTIONAL)
    # Will not try to make orders when balance is below set amount
    # 
    # Format:
    # coin: amount
    ##########
    coinmins:
      SXC: 1            # require SXC balance >= 1 before trying to sell
      DGC: 1            # require DGC balance >= 1 before trying to sell
      FST: 1            # require FST balance >= 1 before trying to sell
      LOT: 100          # require LOT balance >= 100 before trying to sell
    
    ##########
    # Coins to exclude from our auto-selling (OPTIONAL)
    #
    # Format: 1 coin per line
    # - coin
    ##########
    excludes:
      - LTC             # Do not autosell LTC
```
NOTE: coinmins and excludes sections are optional.
