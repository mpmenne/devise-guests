require "spec_helper"
require "ostruct"

describe ApplicationController, type: :controller do
  controller do
  end

  before(:each) do
    @mock_warden = OpenStruct.new
    @controller.request.env["warden"] = @mock_warden
  end

  it "should create an anonymous user for a guest" do
    allow(@mock_warden).to receive(:authenticate).with(anything).and_return(false)

    expect(@controller.current_or_guest_user.email).to match(/guest/)
  end

  it "should use the current user when available" do
    m = double
    allow(@mock_warden).to receive(:authenticate).with(anything).and_return(m)

    expect(@controller.current_or_guest_user).to eq(m)
  end

  it "should use the guest user when a guest has already been created" do
    email = @controller.send(:guest_email_authentication_key, 123)
    allow(@mock_warden).to receive(:authenticate).with(anything).and_return(false)
    allow(@controller).to receive(:session) { {guest_user_id: email} }
    allow(User).to receive(:find_by).with(email:) { double(email:) }

    expect(@controller).not_to receive(:create_guest_user)

    expect(@controller.current_or_guest_user.email).to eq(email)
  end

  it "should run the 'logging_in' callbacks" do
    # A user is logged in
    current_user = double
    allow(@controller).to receive(:current_user) { current_user }

    # There is a guest user instance
    guest_user = double
    allow(guest_user).to receive(:destroy)
    allow(@controller).to receive(:guest_user) { guest_user }
    allow(@controller).to receive(:session) { {guest_user_id: 123} }

    expect(@controller).to receive(:run_callbacks).with(:logging_in_user).and_call_original
    expect(@controller).to receive(:transfer_guest_to_user).and_call_original

    @controller.current_or_guest_user
  end

  it "should define a 'logging_in' callback" do
    expect(@controller).to respond_to(:_logging_in_user_callbacks)
  end
end
