# puppet-winlogbeat

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with winlogbeat](#setup)
    - [What winlogbeat affects](#what-winlogbeat-affects)
    - [Setup requirements](#setup-requirements)
    - [Beginning with winlogbeat](#beginning-with-winlogbeat)
3. [Usage - Configuration options and additional functionality](#usage)
    - [Adding an Input](#adding-an-input)
      - [Multiline Logs](#multiline-logs)
      - [JSON logs](#json-logs)
    - [Inputs in hiera](#inputs-in-hiera)
    - [Usage on Windows](#usage-on-windows)
    - [Processors](#processors)
    - [Index Lifecycle Management](#index-lifecycle-management)
4. [Reference](#reference)
    - [Public Classes](#public-classes)
    - [Private Classes](#private-classes)
    - [Public Defines](#public-defines)
5. [Limitations - OS compatibility, etc.](#limitations)
    - [Pre-1.9.1 Ruby](#pre-191-ruby)
    - [Using config_file](#using-config_file)
6. [Development - Guide for contributing to the module](#development)

## Description

The `winlogbeat` module installs and configures the [winlogbeat log shipper](https://www.elastic.co/products/beats/winlogbeat) maintained by elastic.

## Setup

### What winlogbeat affects

By default `winlogbeat` adds a software repository to your system, and installs winlogbeat along
with required configurations.

### Upgrading to winlogbeat 7.x

To upgrade to winlogbeat 7.x, simply set `$winlogbeat::major_version` to `7` and `$winlogbeat::package_ensure` to `latest` (or whichever version of 7.x you want, just not present).

You'll also need to change instances of `winlogbeat::prospector` to `winlogbeat::input` when upgrading to version 4.x of
this module.


### Setup Requirements

The `winlogbeat` module depends on [`puppetlabs/stdlib`](https://forge.puppetlabs.com/puppetlabs/stdlib), and on
[`puppetlabs/apt`](https://forge.puppetlabs.com/puppetlabs/apt) on Debian based systems.

### Beginning with winlogbeat

`winlogbeat` can be installed with `puppet module install pcfens-winlogbeat` (or with r10k, librarian-puppet, etc.)

The only required parameter, other than which files to ship, is the `outputs` parameter.

## Usage

All of the default values in winlogbeat follow the upstream defaults (at the time of writing).

To ship files to [elasticsearch](https://www.elastic.co/guide/en/beats/winlogbeat/current/winlogbeat-configuration-details.html#elasticsearch-output):
```puppet
class { 'winlogbeat':
  outputs => {
    'elasticsearch' => {
     'hosts' => [
       'http://localhost:9200',
       'http://anotherserver:9200'
     ],
     'loadbalance' => true,
     'cas'         => [
        '/etc/pki/root/ca.pem',
     ],
    },
  },
}

```

To ship log files through [logstash](https://www.elastic.co/guide/en/beats/winlogbeat/current/winlogbeat-configuration-details.html#logstash-output):
```puppet
class { 'winlogbeat':
  outputs => {
    'logstash'     => {
     'hosts' => [
       'localhost:5044',
       'anotherserver:5044'
     ],
     'loadbalance' => true,
    },
  },
}

```

[Shipper](https://www.elastic.co/guide/en/beats/winlogbeat/current/winlogbeat-configuration-details.html#configuration-shipper) and
[logging](https://www.elastic.co/guide/en/beats/winlogbeat/current/winlogbeat-configuration-details.html#configuration-logging) options
can be configured the same way, and are documented on the [elastic website](https://www.elastic.co/guide/en/beats/winlogbeat/current/index.html).

#### Multiline Logs

winlogbeat inputs can handle multiline log entries. The `multiline`
parameter accepts a hash containing `pattern`, `negate`, `match`, `max_lines`, and `timeout`
as documented in the winlogbeat [configuration documentation](https://www.elastic.co/guide/en/beats/winlogbeat/current/multiline-examples.html).

#### JSON Logs

winlogbeat inputs (versions >= 5.0) can natively decode JSON objects if they are stored one per line. The `json`
parameter accepts a hash containing `message_key`, `keys_under_root`, `overwrite_keys`, and `add_error_key`
as documented in the winlogbeat [configuration documentation](https://www.elastic.co/guide/en/beats/winlogbeat/5.5/configuration-winlogbeat-options.html#config-json).

### Inputs in Hiera

Inputs can be defined in hiera using the `inputs` parameter. By default, hiera will not merge
input declarations down the hiera hierarchy. That behavior can be changed by configuring the
[lookup_options](https://docs.puppet.com/puppet/latest/reference/lookup_quick.html#setting-lookupoptions-in-data)
flag.

`inputs` can be a Hash that will follow all the parameters listed on this documentation or an
Array that will output as is to the input config file.

### Usage on Windows

When installing on Windows, this module will download the windows version of winlogbeat from
[elastic](https://www.elastic.co/downloads/beats/winlogbeat) to `C:\Temp` by default. The directory
can be overridden using the `tmp_dir` parameter. `tmp_dir` is not managed by this module,
but is expected to exist as a directory that puppet can write to.

### Processors

winlogbeat 5.0 and greater includes a new libbeat feature for filtering and/or enhancing all
exported data through processors before being sent to the configured output(s). They can be
defined as a hash added to the class declaration (also used for automatically creating
processors using hiera), or as their own defined resources.

To drop the offset and input_type fields from all events:

```puppet
class {'winlogbeat':
  processors => [
    {
      'drop_fields' => {
        'fields' => ['input_type', 'offset'],
      }
    }
  ],
}
```

To drop all events that have the http response code equal to 200:
input
```puppet
class {'winlogbeat':
  processors => [
    {
      'drop_event' => {
        'when' => {'equals' => {'http.code' => 200}}
      }
    }
  ],
}
```

Now to combine these examples into a single definition:

```puppet
class {'winlogbeat':
  processors => [
    {
      'drop_fields' => {
        'params'   => {'fields' => ['input_type', 'offset']},
        'priority' => 1,
      }
    },
    {
      'drop_event' => {
        'when'     => {'equals' => {'http.code' => 200}},
        'priority' => 2,
      }
    }
  ],
}
```

For more information please review the documentation [here](https://www.elastic.co/guide/en/beats/winlogbeat/5.1/configuration-processors.html).

#### Processors in Hiera

Processors can be declared in hiera using the `processors` parameter. By default, hiera will not merge
processor declarations down the hiera hierarchy. That behavior can be changed by configuring the
[lookup_options](https://docs.puppet.com/puppet/latest/reference/lookup_quick.html#setting-lookupoptions-in-data)
flag.

### Index Lifecycle Management

You can override the default winlogbeat ILM policy by specifying `ilm.policy` hash in `winlogbeat::setup` parameter:

```
winlogbeat::setup:
  ilm.policy:
    phases:
      hot:
        min_age: "0ms"
        actions:
          rollover:
            max_size: "10gb"
            max_age: "1d"
```

## Reference
 - [**Public Classes**](#public-classes)
    - [Class: winlogbeat](#class-winlogbeat)
 - [**Private Classes**](#private-classes)
    - [Class: winlogbeat::config](#class-winlogbeatconfig)
    - [Class: winlogbeat::install](#class-winlogbeatinstall)
    - [Class: winlogbeat::params](#class-winlogbeatparams)
    - [Class: winlogbeat::repo](#class-winlogbeatrepo)
    - [Class: winlogbeat::service](#class-winlogbeatservice)
    - [Class: winlogbeat::install::linux](#class-winlogbeatinstalllinux)
    - [Class: winlogbeat::install::windows](#class-winlogbeatinstallwindows)
 - [**Public Defines**](#public-defines)
    - [Define: winlogbeat::input](#define-winlogbeatinput)
    - [Define: winlogbeat::processors](#define-winlogbeatprocessor)

### Public Classes

#### Class: `winlogbeat`

Installs and configures winlogbeat.

**Parameters within `winlogbeat`**
- `package_ensure`: [String] The ensure parameter for the winlogbeat package If set to absent,
  inputs and processors passed as parameters are ignored and everything managed by
  puppet will be removed. (default: present)
- `manage_repo`: [Boolean] Whether or not the upstream (elastic) repo should be configured or not (default: true)
- `major_version`: [Enum] The major version of winlogbeat to install. Should be either `'5'` or `'6'`. The default value is `'6'`, except
   for OpenBSD 6.3 and earlier, which has a default value of `'5'`.
- `service_ensure`: [String] The ensure parameter on the winlogbeat service (default: running)
- `service_enable`: [String] The enable parameter on the winlogbeat service (default: true)
- `param repo_priority`: [Integer] Repository priority.  yum and apt supported (default: undef)
- `service_provider`: [String] The provider parameter on the winlogbeat service (default: on RedHat based systems use redhat, otherwise undefined)
- `spool_size`: [Integer] How large the spool should grow before being flushed to the network (default: 2048)
- `idle_timeout`: [String] How often the spooler should be flushed even if spool size isn't reached (default: 5s)
- `publish_async`: [Boolean] If set to true winlogbeat will publish while preparing the next batch of lines to transmit (default: false)
- `config_file`: [String] Where the configuration file managed by this module should be placed. If you think
  you might want to use this, read the [limitations](#using-config_file) first. Defaults to the location
  that winlogbeat expects for your operating system.
- `config_dir`: [String] The directory where inputs should be defined (default: /etc/winlogbeat/conf.d)
- `config_dir_mode`: [String] The permissions mode set on the configuration directory (default: 0755)
- `config_dir_owner`: [String] The owner of the configuration directory (default: root). Linux only.
- `config_dir_group`: [String] The group of the configuration directory (default: root). Linux only.
- `config_file_mode`: [String] The permissions mode set on configuration files (default: 0644)
- `config_file_owner`: [String] The owner of the configuration files, including inputs (default: root). Linux only.
- `config_file_group`: [String] The group of the configuration files, including inputs (default: root). Linux only.
- `purge_conf_dir`: [Boolean] Should files in the input configuration directory not managed by puppet be automatically purged
- `enable_conf_modules`: [Boolean] Should winlogbeat.config.modules be enabled
- `outputs`: [Hash] Will be converted to YAML for the required outputs section of the configuration (see documentation, and above)
- `shipper`: [Hash] Will be converted to YAML to create the optional shipper section of the winlogbeat config (see documentation)
- `logging`: [Hash] Will be converted to YAML to create the optional logging section of the winlogbeat config (see documentation)
- `systemd_beat_log_opts_override`: [String] Will overide the default `BEAT_LOG_OPTS=-e`. Required if using `logging` hash on systems running with systemd. required: Puppet 6.1+, winlogbeat 7+,
- `modules`: [Array] Will be converted to YAML to create the optional modules section of the winlogbeat config (see documentation)
- `modulesd`: [Hash] Used to fill in the templates stored in modules.d
- `conf_template`: [String] The configuration template to use to generate the main winlogbeat.yml config file.
- `download_url`: [String] The URL of the zip file that should be downloaded to install winlogbeat (windows only)
- `install_dir`: [String] Where winlogbeat should be installed (windows only)
- `tmp_dir`: [String] Where winlogbeat should be temporarily downloaded to so it can be installed (windows only)
- `shutdown_timeout`: [String] How long winlogbeat waits on shutdown for the publisher to finish sending events
- `beat_name`: [String] The name of the beat shipper (default: hostname)
- `tags`: [Array] A list of tags that will be included with each published transaction
- `max_procs`: [Number] The maximum number of CPUs that can be simultaneously used
- `fields`: [Hash] Optional fields that should be added to each event output
- `fields_under_root`: [Boolean] If set to true, custom fields are stored in the top level instead of under fields
- `disable_config_test`: [Boolean] If set to true, configuration tests won't be run on config files before writing them.
- `processors`: [Array] Processors that should be configured.
- `monitoring`: [Hash] The monitoring.* components of the winlogbeat configuration.
- `inputs`: [Hash] or [Array] Inputs that will be created. Commonly used to create inputs using hiera
- `setup`: [Hash] Setup that will be created. Commonly used to create setup using hiera
- `xpack`: [Hash] XPack configuration to pass to winlogbeat

### Private Classes

#### Class: `winlogbeat::config`

Creates the configuration files required for winlogbeat (but not the inputs)

#### Class: `winlogbeat::install`

Calls the correct installer class based on the kernel fact.

#### Class: `winlogbeat::params`

Sets default parameters for `winlogbeat` based on the OS and other facts.

#### Class: `winlogbeat::repo`

Installs the yum or apt repository for the system package manager to install winlogbeat.

#### Class: `winlogbeat::service`

Configures and manages the winlogbeat service.

#### Class: `winlogbeat::install::linux`

Install the winlogbeat package on Linux kernels.

#### Class: `winlogbeat::install::windows`

Downloads, extracts, and installs the winlogbeat zip file in Windows.

### Public Defines

#### Define: `winlogbeat::input`

Installs a configuration file for a input.

Be sure to read the [winlogbeat configuration details](https://www.elastic.co/guide/en/beats/winlogbeat/current/winlogbeat-configuration-details.html)
to fully understand what these parameters do.

**Parameters for `winlogbeat::input`**
  - `ensure`: The ensure parameter on the input configuration file. (default: present)
  - `paths`: [Array] The paths, or blobs that should be handled by the input. (required if input_type is _log_)
  - `containers_ids`: [Array] If input_type is _docker_, the list of Docker container ids to read the logs from. (default: '*')
  - `containers_path`: [String] If input_type is _docker_, the path from where the logs should be read from. (default: /var/log/docker/containers)
  - `containers_stream`: [String] If input_type is _docker_, read from the specified stream only. (default: all)
  - `combine_partial`: [Boolean] If input_type is _docker_, enable partial messages joining. (default: false)
  - `cri_parse_flags`: [Boolean] If input_type is _docker_, enable CRI flags parsing from the log file. (default: false)
  - `syslog_protocol`: [Enum tcp,udp] Syslog protocol (default: udp)
  - `syslog_host`: [String] Host to listen for syslog messages (default: localhost:5140)
  - `exclude_files`: [Array] Files that match any regex in the list are excluded from winlogbeat (default: [])
  - `encoding`: [String] The file encoding. (default: plain)
  - `input_type`: [String] where winlogbeat reads the log from (default:log)
  - `fields`: [Hash] Optional fields to add information to the output (default: {})
  - `fields_under_root`: [Boolean] Should the `fields` parameter fields be stored at the top level of indexed documents.
  - `ignore_older`: [String] Files older than this field will be ignored by winlogbeat (default: ignore nothing)
  - `close_older`: [String] Files that haven't been modified since `close_older`, they'll be closed. New
  modifications will be read when files are scanned again according to `scan_frequency`. (default: 1h)
  - `log_type`: [String] \(Deprecated - use `doc_type`\) The document_type setting (optional - default: log)
  - `doc_type`: [String] The event type to used for published lines, used as type field in logstash
    and elasticsearch (optional - default: log)
  - `scan_frequency`: [String] How often should the input check for new files (default: 10s)
  - `harvester_buffer_size`: [Integer] The buffer size the harvester uses when fetching the file (default: 16384)
  - `tail_files`: [Boolean] If true, winlogbeat starts reading new files at the end instead of the beginning (default: false)
  - `backoff`: [String] How long winlogbeat should wait between scanning a file after reaching EOF (default: 1s)
  - `max_backoff`: [String] The maximum wait time to scan a file for new lines to ship (default: 10s)
  - `backoff_factor`: [Integer] `backoff` is multiplied by this parameter until `max_backoff` is reached to
    determine the actual backoff (default: 2)
  - `force_close_files`: [Boolean] Should winlogbeat forcibly close a file when renamed (default: false)
  - `pipeline`: [String] winlogbeat can be configured for a different ingest pipeline for each input (default: undef)
  - `include_lines`: [Array] A list of regular expressions to match the lines that you want to include.
    Ignored if empty (default: [])
  - `exclude_lines`: [Array] A list of regular expressions to match the files that you want to exclude.
    Ignored if empty (default: [])
  - `max_bytes`: [Integer] The maximum number of bytes that a single log message can have (default: 10485760)
  - `tags`: [Array] A list of tags to send along with the log data.
  - `json`: [Hash] Options that control how winlogbeat handles decoding of log messages in JSON format
    [See above](#json-logs). (default: {})
  - `multiline`: [Hash] Options that control how winlogbeat handles log messages that span multiple lines.
    [See above](#multiline-logs). (default: {})

## Limitations
This module doesn't load the [elasticsearch index template](https://www.elastic.co/guide/en/beats/winlogbeat/current/winlogbeat-getting-started.html#winlogbeat-template) into elasticsearch (required when shipping
directly to elasticsearch).

When installing on Windows, there's an expectation that `C:\Temp` already exists, or an alternative
location specified in the `tmp_dir` parameter exists and is writable by puppet. The temp directory
is used to store the downloaded installer only.

### Generic template

By default, a generic, open ended template is used that simply converts your configuration into
a hash that is produced as YAML on the system. To use a template that is more strict, but possibly
incomplete, set `conf_template` to `winlogbeat/winlogbeat.yml.erb`.

### Debian Systems

winlogbeat 5.x and newer requires apt-transport-https, but this module won't install it for you.

### Using config_file
There are a few very specific use cases where you don't want this module to directly manage the winlogbeat
configuration file, but you still want the configuration file on the system at a different location.
Setting `config_file` will write the winlogbeat configuration file to an alternate location, but it will not
update the init script. If you don't also manage the correct file (/etc/winlogbeat/winlogbeat.yml on Linux,
C:/Program Files/winlogbeat/winlogbeat.yml on Windows) then winlogbeat won't be able to start.

If you're copying the alternate config file location into the real location you'll need to include some
metaparameters like
```puppet
file { '/etc/winlogbeat/winlogbeat.yml':
  ensure  => file,
  source  => 'file:///etc/winlogbeat/winlogbeat.special',
  require => File['winlogbeat.yml'],
  notify  => Service['winlogbeat'],
}
```
to ensure that services are managed like you might expect.

### Logging on systems with Systemd and with version winlogbeat 7.0+ installed
With winlogbeat version 7+ running on systems with systemd, the winlogbeat systemd service file contains a default that will ignore the logging hash parameter

```
Environment="BEAT_LOG_OPTS=-e`
```
to overide this default, you will need to set the systemd_beat_log_opts_override parameter to empty string

example:
```puppet
class {'winlogbeat':
  logging => {
    'level'     => 'debug',
    'to_syslog' => false,
    'to_files'  => true,
    'files'     => {
      'path'        => '/var/log/winlogbeat',
      'name'        => 'winlogbeat',
      'keepfiles'   => '7',
      'permissions' => '0644'
    },
  systemd_beat_log_opts_override => "",
}
```

this will only work on systems with puppet version 6.1+. On systems with puppet version < 6.1 you will need to `systemctl daemon-reload`. This can be achived by using the [camptocamp-systemd](https://forge.puppet.com/camptocamp/systemd)

```puppet
include systemd::systemctl::daemon_reload

class {'winlogbeat':
  logging => {
...
    },
  systemd_beat_log_opts_override => "",
  notify  => Class['systemd::systemctl::daemon_reload'],
}
```

## Development

Pull requests and bug reports are welcome. If you're sending a pull request, please consider
writing tests if applicable.
