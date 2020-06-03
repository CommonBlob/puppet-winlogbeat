# winlogbeat::config
#
# Manage the configuration files for winlogbeat
#
# @summary A private class to manage the winlogbeat config file
class winlogbeat::config {
  $major_version = $winlogbeat::major_version

  if has_key($winlogbeat::setup, 'ilm.policy') {
    file {"${winlogbeat::config_dir}/ilm_policy.json":
      content => to_json({'policy' => $winlogbeat::setup['ilm.policy']}),
      notify  => Service['winlogbeat'],
      require => File['winlogbeat-config-dir'],
    }
    $setup = $winlogbeat::setup - 'ilm.policy' + {'ilm.policy_file' => "${winlogbeat::config_dir}/ilm_policy.json"}
  } else {
    $setup = $winlogbeat::setup
  }

  if versioncmp($major_version, '6') >= 0 {
    $winlogbeat_config_temp = delete_undef_values({
      'shutdown_timeout'  => $winlogbeat::shutdown_timeout,
      'name'              => $winlogbeat::beat_name,
      'tags'              => $winlogbeat::tags,
      'max_procs'         => $winlogbeat::max_procs,
      'cloud_id'          => $winlogbeat::cloud_id,
      'cloud_auth'        => $winlogbeat::cloud_auth,
      'fields'            => $winlogbeat::fields,
      'fields_under_root' => $winlogbeat::fields_under_root,
      'winlogbeat'          => {
        'config.inputs' => {
          'enabled' => true,
          'path'    => "${winlogbeat::config_dir}/*.yml",
        },
        'shutdown_timeout'   => $winlogbeat::shutdown_timeout,
        'modules'           => $winlogbeat::modules,
      },
      'http'              => $winlogbeat::http,
      'output'            => $winlogbeat::outputs,
      'shipper'           => $winlogbeat::shipper,
      'logging'           => $winlogbeat::logging,
      'runoptions'        => $winlogbeat::run_options,
      'processors'        => $winlogbeat::processors,
      'monitoring'        => $winlogbeat::monitoring,
      'setup'             => $setup,
    })
    # Add the 'xpack' section if supported (version >= 6.1.0) and not undef
    if $winlogbeat::xpack and versioncmp($winlogbeat::package_ensure, '6.1.0') >= 0 {
      $winlogbeat_config = deep_merge($winlogbeat_config_temp, {'xpack' => $winlogbeat::xpack})
    }
    else {
      $winlogbeat_config = $winlogbeat_config_temp
    }
  } else {
    $winlogbeat_config_temp = delete_undef_values({
      'shutdown_timeout'  => $winlogbeat::shutdown_timeout,
      'name'              => $winlogbeat::beat_name,
      'tags'              => $winlogbeat::tags,
      'queue_size'        => $winlogbeat::queue_size,
      'max_procs'         => $winlogbeat::max_procs,
      'cloud_id'          => $winlogbeat::cloud_id,
      'cloud_auth'        => $winlogbeat::cloud_auth,
      'fields'            => $winlogbeat::fields,
      'fields_under_root' => $winlogbeat::fields_under_root,
      'winlogbeat'          => {
        'spool_size'       => $winlogbeat::spool_size,
        'idle_timeout'     => $winlogbeat::idle_timeout,
        'registry_file'    => $winlogbeat::registry_file,
        'publish_async'    => $winlogbeat::publish_async,
        'config_dir'       => $winlogbeat::config_dir,
        'shutdown_timeout' => $winlogbeat::shutdown_timeout,
      },
      'output'            => $winlogbeat::outputs,
      'shipper'           => $winlogbeat::shipper,
      'logging'           => $winlogbeat::logging,
      'runoptions'        => $winlogbeat::run_options,
      'processors'        => $winlogbeat::processors,
    })
    # Add the 'modules' section if supported (version >= 5.2.0)
    if versioncmp($winlogbeat::package_ensure, '5.2.0') >= 0 {
      $winlogbeat_config = deep_merge($winlogbeat_config_temp, {'modules' => $winlogbeat::modules})
    }
    else {
      $winlogbeat_config = $winlogbeat_config_temp
    }
  }

  if 'winlogbeat_version' in $facts and $facts['winlogbeat_version'] != false {
    $skip_validation = versioncmp($facts['winlogbeat_version'], $winlogbeat::major_version) ? {
      -1      => true,
      default => false,
    }
  } else {
    $skip_validation = false
  }

  case $::kernel {
    'Windows' : {
      $cmd_install_dir = regsubst($winlogbeat::install_dir, '/', '\\', 'G')
      $winlogbeat_path = join([$cmd_install_dir, 'Winlogbeat', 'winlogbeat.exe'], '\\')

      $validate_cmd = ($winlogbeat::disable_config_test or $skip_validation) ? {
        true    => undef,
        default => $major_version ? {
          '7'     => "\"${winlogbeat_path}\" test config -c \"%\"",
          default => "\"${winlogbeat_path}\" -N -configtest -c \"%\"",
        }
      }

      file {'winlogbeat.yml':
        ensure       => $winlogbeat::file_ensure,
        path         => $winlogbeat::config_file,
        content      => template($winlogbeat::conf_template),
        validate_cmd => $validate_cmd,
        notify       => Service['winlogbeat'],
        require      => File['winlogbeat-config-dir'],
      }

      file {'winlogbeat-config-dir':
        ensure  => $winlogbeat::directory_ensure,
        path    => $winlogbeat::config_dir,
        recurse => $winlogbeat::purge_conf_dir,
        purge   => $winlogbeat::purge_conf_dir,
        force   => true,
      }
    } # end Windows

    default : {
      fail($winlogbeat::kernel_fail_message)
    }
  }
}
