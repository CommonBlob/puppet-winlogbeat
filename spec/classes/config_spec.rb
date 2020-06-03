require 'spec_helper'

describe 'winlogbeat::config' do
  let :pre_condition do
    'include ::winlogbeat'
  end

  on_supported_os(facterversion: '2.4').each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:pre_condition) { "class { 'winlogbeat': major_version => '#{major_version}' }" }

      [5, 6].each do |version|
        context "with $major_version == #{version}" do
          let(:major_version) { version }

          let(:validate_cmd) do
            path = case os_facts[:os]['family']
                   when 'Archlinux'
                     '/usr/bin/winlogbeat'
                   else
                     '/usr/share/winlogbeat/bin/winlogbeat'
                   end

            case major_version
            when 5
              "#{path} -N -configtest -c %"
            else
              "#{path} -c % test config"
            end
          end

          case os_facts[:kernel]

          when 'Windows'
            it {
              is_expected.to contain_file('winlogbeat.yml').with(
                ensure: 'file',
                path: 'C:/Program Files/Winlogbeat/winlogbeat.yml',
                notify: 'Service[winlogbeat]',
                require: 'File[winlogbeat-config-dir]',
              )
            }

            it {
              is_expected.to contain_file('winlogbeat-config-dir').with(
                ensure: 'directory',
                path: 'C:/Program Files/Winlogbeat/conf.d',
                recurse: true,
                purge: true,
              )
            }

          end
        end
      end
    end
  end
end
