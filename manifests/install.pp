# winlogbeat::install
#
# A private class to manage the installation of Winlogbeat
#
# @summary A private class that manages the install of Winlogbeat
class winlogbeat::install {
  anchor { 'winlogbeat::install::begin': }

  case $::kernel {
    'Windows': {
      class{'::winlogbeat::install::windows':
        notify => Class['winlogbeat::service'],
      }
      Anchor['winlogbeat::install::begin'] -> Class['winlogbeat::install::windows'] -> Anchor['winlogbeat::install::end']
    }
    default:   {
      fail($winlogbeat::kernel_fail_message)
    }
  }

  anchor { 'winlogbeat::install::end': }

}
