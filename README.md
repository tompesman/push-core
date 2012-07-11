# Push

Please note this gem not yet used in production. If you want to help, please contact me.

## Installation

Add to your `GemFile`

    gem push-core

and add the push provider to you Gemfile:

For __APNS__ (iOS: Apple Push Notification Services):

    gem push-apns
    
For __C2DM__ (Android: Cloud to Device Messaging, deprecated):

    gem push-c2dm

For __GCM__ (Android: Google Cloud Messaging):

    gem push-gcm

And run `bundle install` to install the gems.

To generate the migration and the configuration files run:

    rails g push
    bundle exec rake db:migrate

## Configuration
A default configuration file looks like this:
```ruby
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

  provider :gcm,
  {
    :connections => 2,
    :key => 'api key'
  }
end
```
Remove the provider you're not using. Add your email and password to enable C2DM and add the API key for GCM. For APNS follow the 'Generating Certificates' below.


### Generating Certificates

1. Open up Keychain Access and select the `Certificates` category in the sidebar.
2. Expand the disclosure arrow next to the iOS Push Services certificate you want to export.
3. Select both the certificate and private key.
4. Right click and select `Export 2 items...`.
5. Save the file as `cert.p12`, make sure the File Format is `Personal Information Exchange (p12)`.
6. If you decide to set a password for your exported certificate, please read the Configuration section below.
7. Convert the certificate to a .pem, where `<environment>` should be `development` or `production`, depending on the certificate you exported.

    `openssl pkcs12 -nodes -clcerts -in cert.p12 -out <environment>.pem`
      
8. Move the .pem file into your Rails application under `config/push`.


## Daemon

To start the daemon:

    bundle exec push <environment> <options>
    
Where `<environment>` is your Rails environment and `<options>` can be `--foreground`, `--version` or `--help`.

## Sending notifications
APNS:
```ruby
Push::MessageApns.new(device: "<APNS device_token here>", alert: 'Hello World', expiry: 1.day.to_i, attributes_for_device: {key: 'MSG'}).save
```
C2DM:
```ruby
Push::MessageC2dm.new(device: "<C2DM registration_id here>", payload: { message: "Hello World" }, collapse_key: "MSG").save
```

GCM:
```ruby
Push::MessageGcm.new(device: "<C2DM registration_id here>", payload: { message: "Hello World" }, collapse_key: "MSG").save
```

## Feedback processing

The push providers return feedback in various ways and these are captured and stored in the `push_feedback` table. The installer installs the `lib/push/feedback_processor.rb` file which is by default called every 60 seconds. In this file you can process the feedback which is different for every application.

## Thanks

This project started as a fork of Ian Leitch [RAPNS](https://github.com/ileitch/rapns) project. The differences between this project and RAPNS is the support for C2DM and the modularity of the push providers.
    