require 'spec_helper'

describe 'winlogbeat::install' do
  let :pre_condition do
    'include ::winlogbeat'
  end

  on_supported_os(facterversion: '2.4').each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to contain_anchor('winlogbeat::install::begin') }
      it { is_expected.to contain_anchor('winlogbeat::install::end') }

      case os_facts[:kernel]

      when 'Windows'
        it { is_expected.to contain_class('winlogbeat::install::windows') }
      end
    end
  end
end
