require 'spec_helper'

describe 'winlogbeat_version' do
  before :each do
    Facter.clear
    Facter.fact(:kernel).stubs(:value).returns('Linux')
  end
  context 'when on a Linux host' do
    before :each do
      File.stubs(:executable?)
      Facter::Util::Resolution.stubs(:exec)
      File.expects(:executable?).with('/usr/share/winlogbeat/bin/winlogbeat').returns true
      Facter::Util::Resolution.stubs(:exec).with('/usr/share/winlogbeat/bin/winlogbeat --version').returns('winlogbeat version 5.1.1 (amd64), libbeat 5.1.1')
    end
    it 'returns the correct version' do
      expect(Facter.fact(:winlogbeat_version).value).to eq('5.1.1')
    end
  end

  context 'when the winlogbeat package is not installed' do
    before :each do
      File.stubs(:executable?)
      Facter::Util::Resolution.stubs(:exec)
      File.expects(:executable?).with('/usr/bin/winlogbeat').returns false
      File.expects(:executable?).with('/usr/local/bin/winlogbeat').returns false
      File.expects(:executable?).with('/usr/share/winlogbeat/bin/winlogbeat').returns false
      File.expects(:executable?).with('/usr/local/sbin/winlogbeat').returns false
      File.stubs(:exist?)
      File.expects(:exist?).with('c:\Program Files\Winlogbeat\winlogbeat.exe').returns false
    end
    it 'returns false' do
      expect(Facter.fact(:winlogbeat_version).value).to eq(false)
    end
  end
end
