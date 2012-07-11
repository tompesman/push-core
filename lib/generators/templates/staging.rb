Push::Daemon::Builder.new do
  daemon
  ({
    :poll => 2,
    :pid_file => 'tmp/pids/push.pid',
    :airbrake_notify => false
  })

  feedback
  ({
    :poll => 60,
    :processor => 'lib/push/feedback_processor'
  })

  provider :apns,
  {
    :certificate => "staging.pem",
    :certificate_password => "",
    :sandbox => true,
    :connections => 3,
    :feedback_poll => 60
  }

  provider :c2dm,
  {
    :connections => 2,
    :email => "",
    :password => ""
  }

  provider :gcm,
  {
    :connections => 2,
    :key => 'api key'
  }
end