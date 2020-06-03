require 'spec_helper'

describe 'winlogbeat' do
  let :pre_condition do
    'include ::winlogbeat'
  end

  on_supported_os(facterversion: '2.4').each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      if os_facts[:kernel] != 'windows'
        it { is_expected.to compile }
      end

      it { is_expected.to contain_class('winlogbeat') }
      it { is_expected.to contain_class('winlogbeat::params') }
      it { is_expected.to contain_anchor('winlogbeat::begin') }
      it { is_expected.to contain_anchor('winlogbeat::end') }
      it { is_expected.to contain_class('winlogbeat::install') }
      it { is_expected.to contain_class('winlogbeat::config') }
      it { is_expected.to contain_class('winlogbeat::service') }
    end
  end
end
