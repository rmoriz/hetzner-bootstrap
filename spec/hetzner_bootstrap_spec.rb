require 'hetzner-api'
require 'spec_helper'

describe "Bootstrap" do
  before(:all) do
    @api = Hetzner::API.new API_USERNAME, API_PASSWORD
    @bootstrap = Hetzner::Bootstrap.new :api => @api
  end

  context "add target" do
    
    it "should be able to add a server to operate on" do
      @bootstrap.add_target proper_target
      @bootstrap.targets.should have(1).target
      @bootstrap.targets.first.should be_instance_of Hetzner::Bootstrap::Target
    end

    it "should have the default template if none is specified" do
      @bootstrap.add_target proper_target
      @bootstrap.targets.first.template.should be_instance_of Hetzner::Bootstrap::Template
    end

    it "should raise an NoTemplateProvidedError when no template option provided" do
      lambda {
      @bootstrap.add_target improper_target_without_template
      }.should raise_error(Hetzner::Bootstrap::Target::NoTemplateProvidedError)
    end
  
  end

  def proper_target
    return {
      :ip            => "1.2.3.4",
      :login         => "root",
#      :password      => "halloMartin!",
      :rescue_os     => "linux",
      :rescue_os_bit => "64",
      :template      => default_template
    }
  end

  def improper_target_without_template
    proper_target.select { |k,v| k != :template }
  end

  def default_template
    "bla"
  end
end


