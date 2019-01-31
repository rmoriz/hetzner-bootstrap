# frozen_string_literal: true

require 'hetzner-api'
require 'hetzner-bootstrap'

# rubocop:disable Metrics/BlockLength
describe 'Bootstrap' do
  let(:bs) do
    Hetzner::Bootstrap.new(api: Hetzner::API.new(API_USERNAME, API_PASSWORD))
  end

  context 'add target' do
    it 'should be able to add a server to operate on' do
      bs.add_target proper_target

      expect(bs.targets.size).to be_eql(1)
      expect(bs.targets.first).to be_instance_of(Hetzner::Bootstrap::Target)
    end

    it 'should have the default template if none is specified' do
      bs.add_target proper_target

      expect(bs.targets.first.template).to be_instance_of Hetzner::Bootstrap::Template
    end
  end

  def proper_target
    {
      ip: '1.2.3.4',
      login: 'root',
      #      :password      => "halloMartin!",
      rescue_os: 'linux',
      rescue_os_bit: '64',
      template: default_template
    }
  end

  def improper_target_without_template
    proper_target.reject { |k, _v| k == :template }
  end

  def default_template
    'string'
  end
end
# rubocop:enable Metrics/BlockLength
