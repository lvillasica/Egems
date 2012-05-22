require "spec_helper"

describe ApplicationController do
  controller do
    def index
      raise DeviseLdapAuthenticatable::LdapException
    end
  end

  describe "handling LDAP exceptions" do
    it "should have a status of 500" do
      post :index
      response.code.should eql("500")
    end
  end
end
