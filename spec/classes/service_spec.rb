require 'spec_helper'

describe 'winlogbeat::service' do
  let :pre_condition do
    'include ::winlogbeat'
  end

  on_supported_os(facterversion: '2.4').each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      if os_facts[:kernel] != 'windows'
        it { is_expected.to compile }
      end

      it {
        is_expected.to contain_service('winlogbeat').with(
          ensure: 'running',
          enable: true,
        )
      }
    end
  end
end
