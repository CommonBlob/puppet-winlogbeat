# winlogbeat::params
#
# Set a number of default parameters
#
# @summary Set a bunch of default parameters
class winlogbeat::params {
  $service_ensure           = running
  $service_enable           = true
  $spool_size               = 2048
  $idle_timeout             = '5s'
  $publish_async            = false
  $shutdown_timeout         = '0'
  $beat_name                = $::fqdn
  $cloud_auth               = undef
  $cloud_id                 = undef
  $tags                     = []
  $max_procs                = undef
  $config_file_mode         = '0644'
  $config_dir_mode          = '0755'
  $purge_conf_dir           = true
  $enable_conf_modules      = false
  $fields                   = {}
  $fields_under_root        = false
  $http                     = {}
  $outputs                  = {}
  $shipper                  = {}
  $logging                  = {}
  $run_options              = {}
  $modules                  = []
  $kernel_fail_message      = "${::kernel} is not supported by winlogbeat."
  $osfamily_fail_message    = "${::osfamily} is not supported by winlogbeat."
  $conf_template            = "${module_name}/pure_hash.yml.erb"
  $disable_config_test      = false
  $xpack                    = undef
  $systemd_override_dir     = '/etc/systemd/system/winlogbeat.service.d'
  $systemd_beat_log_opts_template = "${module_name}/systemd/logging.conf.erb"

  # These are irrelevant as long as the template is set based on the major_version parameter
  # if versioncmp('1.9.1', $::rubyversion) > 0 {
  #   $conf_template = "${module_name}/winlogbeat.yml.ruby18.erb"
  # } else {
  #   $conf_template = "${module_name}/winlogbeat.yml.erb"
  # }
  #

  $manage_repo = true
  $manage_apt  = true
  $winlogbeat_path = '/usr/share/winlogbeat/bin/winlogbeat'
  $major_version = '7'

  case $::kernel {

    'Windows' : {
      $package_ensure   = '7.1.0'
      $config_file_owner = 'Administrator'
      $config_file_group = undef
      $config_dir_owner = 'Administrator'
      $config_dir_group = undef
      $config_file      = 'C:/Program Files/Winlogbeat/winlogbeat.yml'
      $config_dir       = 'C:/Program Files/Winlogbeat/conf.d'
      $install_dir      = 'C:/Program Files'
      $tmp_dir          = 'C:/Windows/Temp'
      $service_provider = undef
      $url_arch         = $::architecture ? {
        'x86'   => 'x86',
        'x64'   => 'x86_64',
        default => fail("${::architecture} is not supported by winlogbeat."),
      }
    }

    default : {
      fail($kernel_fail_message)
    }
  }
}
