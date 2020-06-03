# winlogbeat::service
#
# Manage the winlogbeat service
#
# @summary Manage the winlogbeat service
class winlogbeat::service {
  service { 'winlogbeat':
    ensure   => $winlogbeat::real_service_ensure,
    enable   => $winlogbeat::real_service_enable,
    provider => $winlogbeat::service_provider,
  }

  $major_version                  = $winlogbeat::major_version
  $systemd_beat_log_opts_override = $winlogbeat::systemd_beat_log_opts_override

  #make sure puppet client version 6.1+ with winlogbeat version 7+, running on systemd
  if ( versioncmp( $major_version, '7'   ) >= 0 and
    $::service_provider == 'systemd' ) {

    if ( versioncmp( $::clientversion, '6.1' ) >= 0 ) {

      unless $systemd_beat_log_opts_override == undef {
        $ensure_overide = 'present'
      } else {
        $ensure_overide = 'absent'
      }

      ensure_resource('file',
        $winlogbeat::systemd_override_dir,
        {
          ensure => 'directory',
        }
      )

      file { "${winlogbeat::systemd_override_dir}/logging.conf":
        ensure  => $ensure_overide,
        content => template($winlogbeat::systemd_beat_log_opts_template),
        require => File[$winlogbeat::systemd_override_dir],
        notify  => Service['winlogbeat'],
      }

    } else {

      unless $systemd_beat_log_opts_override == undef {
        $ensure_overide = 'present'
      } else {
        $ensure_overide = 'absent'
      }

      if !defined(File[$winlogbeat::systemd_override_dir]) {
        file{$winlogbeat::systemd_override_dir:
          ensure => 'directory',
        }
      }

      file { "${winlogbeat::systemd_override_dir}/logging.conf":
        ensure  => $ensure_overide,
        content => template($winlogbeat::systemd_beat_log_opts_template),
        require => File[$winlogbeat::systemd_override_dir],
        notify  => Service['winlogbeat'],
      }

      unless defined('systemd') {
        warning('You\'ve specified an $systemd_beat_log_opts_override varible on a system running puppet version < 6.1 and not declared "systemd" resource See README.md for more information') # lint:ignore:140chars
      }
    }
  }

}
