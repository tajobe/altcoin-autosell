altcoin-autosell
================

Cryptocurrency/altcoin autoseller script written in Perl, loosely based on dtbartle/altcoin-autosell.

Currently supports CoinEx. Support for Cryptsy coming soon.

Running
-------

### Dependencies
Requires modules Digest::SHA, HTTP::Request, JSON, Log::Log4perl, LWP::Protocol::https, LWP::UserAgent, Try::Tiny, and YAML::Tiny.  
Install using CPAN:
```shell
cpan Digest::SHA HTTP::Request JSON Log::Log4perl LWP::Protocol::https LWP::UserAgent Try::Tiny YAML::Tiny
```

### Usage
```shell
./autoseller.pl # just run
perl autoseller.pl # just run
./autoseller.pl -usage # show usage
```

### Configuration
Log configuration(for debugging) located in log.conf. For example, to debug the config loading, turn log level up of `log4perl.logger.Autosell.Config` to DEBUG or higher, TRACE.

Edit configuration in config.yml, or create one and pass it on the command line with the -config option.
Example config(included):
```yaml
    ##########
    # General settings
    ##########
    general:
        # Amount of time between polls
        poll-time: 300
        # Delay when we are going to send a request
        request-delay: 5
        # strategy to use to sell coins
        #   match-buy: Match highest buy offer(quick sell, least money)
        #   match-sell: Match lowest sell offer(takes longer, most money)
        #   undercut-sell: Undercuts lowest sell by max( int(5%), 1 Satoshi )
        strategy: match-buy
        # Target currency(btc/ltc/doge)
        target: BTC
    
    ##########
    # Any number of API keys for us to monitor/use
    # 
    # Format:
    #   exchange: (coinex)
    #       key: 'API key'
    #       secret: 'API secret'
    ##########
    apikeys:
        # exchange the keys are for(determines what API we need to use)
        coinex:
            # API key
            key: ''
            # API secret
            secret: ''
    
    ##########
    # Min sell amounts for any number of coins (OPTIONAL)
    # Will not try to make orders when balance is below set amount
    # 
    # Format:
    #   coin: amount
    ##########
    coinmins:
        # require SXC balance >= 1 before trying to sell
        SXC: 1
        # require DGC balance >= 1 before trying to sell
        DGC: 1
        # require FST balance >= 1 before trying to sell
        FST: 1
        # require LOT balance >= 1000 before trying to sell
        LOT: 100
    
    ##########
    # Coins to exclude from our auto-selling (OPTIONAL)
    #
    # Format: 1 coin per line
    #   - coin
    ##########
    excludes:
        # Do not autosell LTC
        - LTC
```
*NOTE*: coinmins and excludes sections are completely optional.
