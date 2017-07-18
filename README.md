# Sensu::Extensions::Graphite

This Extensions use Graphite `plaintext` protocol to relay metrics. It opens a presistant TCP connection to Graphite to send its metrics.

## Install

1. Using RubyGem (using sensu vendor ruby) :

```bash
$> /opt/sensu/embedded/bin/gem install sensu-extensions-graphite
``` 

2. Using RPM :

```bash
$> rpm -Uvh https://github.com/amine7536/sensu-extensions-graphite/releases/download/v0.0.2/rubygem-sensu-extensions-graphite-0.0.2-1.noarch.rpm
```

## Configuration

1. Enable the extension :

Add the following to your Sensu configuration `/etc/sensu/conf.d/extensions.json` :

```json
{
  "extensions": {
    "graphite": {
      "gem": "sensu-extensions-graphite"
    }
  }
}
```

2. Configure the extention :

Add the following to your Sensu configuration `/etc/sensu/conf.d/graphite.json` :

```json
{
  "graphite": {
    "name": "graphite",
    "host": "192.168.43.21",
    "port": 9000
  }
}
```

3. Example metric :

```json
{
  "checks": {
    "vmstat_metrics": {
      "type": "metric",
      "handlers": ["graphite"],
      "command": "/etc/sensu/plugins/vmstat-metrics.rb --scheme stats.:::name:::",
      "interval": 10,
      "subscribers": ["all"]
    }
  }
}
```