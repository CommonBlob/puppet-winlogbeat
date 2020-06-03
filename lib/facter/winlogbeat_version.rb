require 'facter'
Facter.add('winlogbeat_version') do
  confine 'kernel' => ['FreeBSD', 'OpenBSD', 'Linux', 'Windows']
  if File.executable?('/usr/bin/winlogbeat')
    winlogbeat_version = Facter::Util::Resolution.exec('/usr/bin/winlogbeat version')
    if winlogbeat_version.empty?
      winlogbeat_version = Facter::Util::Resolution.exec('/usr/bin/winlogbeat --version')
    end
  elsif File.executable?('/usr/local/bin/winlogbeat')
    winlogbeat_version = Facter::Util::Resolution.exec('/usr/local/bin/winlogbeat version')
    if winlogbeat_version.empty?
      winlogbeat_version = Facter::Util::Resolution.exec('/usr/local/bin/winlogbeat --version')
    end
  elsif File.executable?('/usr/share/winlogbeat/bin/winlogbeat')
    winlogbeat_version = Facter::Util::Resolution.exec('/usr/share/winlogbeat/bin/winlogbeat --version')
  elsif File.executable?('/usr/local/sbin/winlogbeat')
    winlogbeat_version = Facter::Util::Resolution.exec('/usr/local/sbin/winlogbeat --version')
  elsif File.exist?('c:\Program Files\Winlogbeat\winlogbeat.exe')
    winlogbeat_version = Facter::Util::Resolution.exec('"c:\Program Files\Winlogbeat\winlogbeat.exe" version')
    if winlogbeat_version.empty?
      winlogbeat_version = Facter::Util::Resolution.exec('"c:\Program Files\Winlogbeat\winlogbeat.exe" --version')
    end
  end
  setcode do
    winlogbeat_version.nil? ? false : %r{^winlogbeat version ([^\s]+)?}.match(winlogbeat_version)[1]
  end
end
