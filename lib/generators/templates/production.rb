Push::Daemon::Builder.new do
  daemon({ :poll => 2, :pid_file => "tmp/pids/push.pid", :airbrake_notify => false })

  provider :apns,
  {
    :certificate => "production.pem",
    :certificate_password => "",
    :sandbox => false,
    :connections => 3,
    :feedback_poll => 60
  }

  provider :c2dm,
  {
    :connections => 2,
    :email => "",
    :password => ""
  }
end