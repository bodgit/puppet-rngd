require 'spec_helper'

describe 'rngd' do
  context 'on unsupported distributions' do
    let(:facts) do
      {
        os: {
          family: 'Unsupported',
        },
      }
    end

    it { expect { is_expected.to compile }.to raise_error(%r{not supported on an Unsupported}) }
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }

      it { is_expected.to contain_class('rngd') }
      it { is_expected.to contain_class('rngd::config') }
      it { is_expected.to contain_class('rngd::install') }
      it { is_expected.to contain_class('rngd::params') }
      it { is_expected.to contain_class('rngd::service') }

      # rubocop:disable RepeatedExample

      case facts[:osfamily]
      when 'RedHat'
        it { is_expected.to contain_file('/etc/sysconfig/rngd') }
        it { is_expected.to contain_package('rng-tools') }
        it { is_expected.to contain_service('rngd') }
        case facts[:operatingsystemmajrelease]
        when '7'
          it { is_expected.to contain_exec('systemctl daemon-reload') }
          it { is_expected.to contain_file('/etc/systemd/system/rngd.service.d') }
          it { is_expected.to contain_file('/etc/systemd/system/rngd.service.d/override.conf') }
          case facts[:selinux]
          when true
            it { is_expected.to contain_file('/etc/systemd/system/rngd.service.d').with_seltype('systemd_unit_file_t') }
            it { is_expected.to contain_file('/etc/systemd/system/rngd.service.d/override.conf').with_seltype('rngd_unit_file_t') }
          end
        end
      when 'Debian'
        it { is_expected.to contain_file('/etc/default/rng-tools') }
        it { is_expected.to contain_package('rng-tools') }
        case facts[:operatingsystem]
        when 'Ubuntu'
          case facts[:operatingsystemrelease]
          when '14.04'
            it { is_expected.to contain_service('rng-tools').with_hasstatus(false) }
          else
            it { is_expected.to contain_service('rng-tools').with_hasstatus(true) }
          end
        else
          it { is_expected.to contain_service('rng-tools').with_hasstatus(true) }
        end
      end
    end
  end
end
