ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require "authlogic/test_case"
require "webmock/test_unit"

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually 
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
  include WebMock::API

  # Sets up dummy xero auth cookies
  def dummy_xero_cookies
    session[:xero_auth] = { :access_token => 'DUMMY', :access_secret => 'DUMMY' }
  end

  # Use WebMock to create fake responses to all the Xero endpoints which
  # we interact with.
  def stub_xero_requests
    filepath = File.dirname(__FILE__) + '/xero_xml/'
    stub_request(:get, 'https://api.xero.com/api.xro/2.0/Contacts').to_return(
      :body => File.read(filepath + 'contacts.xml'))
    stub_request(:get, 'https://api.xero.com/api.xro/2.0/Accounts').to_return(
      :body => File.read(filepath + 'accounts.xml'))
    stub_request(:put, 'https://api.xero.com/api.xro/2.0/Invoices').to_return(
      :body => File.read(filepath + 'create_invoice.xml'))
  end

  # stub the xero requests so any call returns 'token expired'
  def stub_xero_requests_with_token_expired
    filepath = File.dirname(__FILE__) + '/xero_xml/'
    stub_request(:get, 'https://api.xero.com/api.xro/2.0/Contacts').to_return(
      :body => File.read(filepath + 'invalid_request_token'), :status => 401)
    stub_request(:get, 'https://api.xero.com/api.xro/2.0/Accounts').to_return(
      :body => File.read(filepath + 'invalid_request_token'), :status => 401)
    stub_request(:put, 'https://api.xero.com/api.xro/2.0/Invoices').to_return(
      :body => File.read(filepath + 'invalid_request_token'), :status => 401)
  end
end
