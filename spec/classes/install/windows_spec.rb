require 'spec_helper'

describe 'winlogbeat::install::windows' do
  let :pre_condition do
    'include ::winlogbeat'
  end

  on_supported_os(facterversion: '2.4').each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      case facts[:kernel]
      when 'windows'
        # it { is_expected.to compile }
        it { is_expected.to contain_file('C:/Program Files').with_ensure('directory') }
        # it {
        #   is_expected.to contain_archive('C:/Windows/Temp/winlogbeat-5.6.2-windows-x86_64.zip').with(
        #     creates: 'C:/Program Files/Winlogbeat/winlogbeat-5.6.2-windows-x86_64',
        #   )
        # }
        # it {
        #   is_expected.to contain_exec('install winlogbeat-5.6.2-windows-x86_64').with(
        #     command: './install-service-winlogbeat.ps1',
        #   )
        # }
        # it {
        #   is_expected.to contain_exec('unzip winlogbeat-5.6.2-windows-x86_64').with(
        #     command: '$sh=New-Object -COM Shell.Application;$sh.namespace((Convert-Path \'C:/Program Files\')).'\
        #              'Copyhere($sh.namespace((Convert-Path \'C:/Windows/Temp/winlogbeat-5.6.2-windows-x86_64.zip\')).items(), 16)',
        #   )
        # }
        # it {
        #   is_expected.to contain_exec('mark winlogbeat-5.6.2-windows-x86_64').with(
        #     command: 'New-Item \'C:/Program Files/Winlogbeat/winlogbeat-5.6.2-windows-x86_64\' -ItemType file',
        #   )
        # }
        # it {
        #   is_expected.to contain_exec('rename winlogbeat-5.6.2-windows-x86_64').with(
        #     command: 'Remove-Item \'C:/Program Files/Winlogbeat\' -Recurse -Force -ErrorAction SilentlyContinue;'\
        #              'Rename-Item \'C:/Program Files/winlogbeat-5.6.2-windows-x86_64\' \'C:/Program Files/Winlogbeat\'',
        #   )
        # }
        # it {
        #   is_expected.to contain_exec('stop service winlogbeat-5.6.2-windows-x86_64').with(
        #     command: 'Set-Service -Name winlogbeat -Status Stopped',
        #   )
        # }
        # it {
        #   is_expected.to contain_file('C:/Windows/Temp/winlogbeat-5.6.2-windows-x86_64.zip').with(
        #     ensure: 'absent',
        #   )
        # }
      else
        it { is_expected.not_to compile }
      end
    end
  end
end
