# winlogbeat::repo
#
# Manage the repository for Winlogbeat (Linux only for now)
#
# @summary Manages the yum, apt, and zypp repositories for Winlogbeat
class winlogbeat::repo {
  $debian_repo_url = "https://artifacts.elastic.co/packages/${winlogbeat::major_version}.x/apt"
  $yum_repo_url = "https://artifacts.elastic.co/packages/${winlogbeat::major_version}.x/yum"

  case $::osfamily {

    default: {
      fail($winlogbeat::osfamily_fail_message)
    }
  }

}
