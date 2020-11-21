require 'spec_helper_acceptance'

describe 'rngd' do
  case fact('osfamily')
  when 'RedHat'
    service = 'rngd'
  when 'Debian'
    service = 'rng-tools'
  end

  it 'works with no errors' do
    pp = <<-EOS
      class { '::rngd':
        hwrng_device => '/dev/urandom',
      }
    EOS

    apply_manifest(pp, catch_failures: true)
    apply_manifest(pp, catch_changes:  true)
  end

  describe file('/etc/default/rng-tools'), if: fact('osfamily').eql?('Debian') do
    it { is_expected.to be_file }
    it { is_expected.to be_mode 644 }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into 'root' }
    its(:content) { is_expected.to match %r{^HRNGDEVICE="\/dev\/urandom"$} }
  end

  describe file('/etc/sysconfig/rngd'), if: fact('osfamily').eql?('RedHat') do
    it { is_expected.to be_file }
    it { is_expected.to be_mode 644 }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into 'root' }
    its(:content) { is_expected.to match %r{^EXTRAOPTIONS="-r \/dev\/urandom"$} }
  end

  describe file('/etc/systemd/system/rngd.service.d/override.conf'), if: (fact('osfamily').eql?('RedHat') && !fact('operatingsystemmajrelease').eql?('6')) do
    it { is_expected.to be_file }
    it { is_expected.to be_mode 644 }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into 'root' }
    its(:sha256sum) { is_expected.to eq 'cb063edc0c2891008c930c1da1f7187b3eeb5521602939678bb0f2f4e2977259' }
  end

  describe service(service), if: fact('osfamily').eql?('RedHat') do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end

  describe service(service), if: fact('operatingsystem').eql?('Debian') do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end

  describe service(service), if: (fact('operatingsystem').eql?('Ubuntu') && !['14.04'].include?(fact('operatingsystemrelease'))) do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end

  # Ubuntu < 16.04 doesn't support 'service rngd status'
  describe service(service), if: (fact('operatingsystem').eql?('Ubuntu') && ['14.04'].include?(fact('operatingsystemrelease'))) do
    it { is_expected.to be_enabled }
  end

  describe process('rngd') do
    it { is_expected.to be_running }
    its(:args) { is_expected.to match %r{-r \/dev\/urandom} }
  end
end
