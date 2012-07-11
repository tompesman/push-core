class PushGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  source_root File.expand_path('../templates', __FILE__)

  def self.next_migration_number(path)
    Time.now.utc.strftime("%Y%m%d%H%M%S")
  end

  def copy_migration
    migration_dir = File.expand_path("db/migrate")

    if !self.class.migration_exists?(migration_dir, 'create_push')
      migration_template "create_push.rb", "db/migrate/create_push.rb"
    end
  end

  def copy_config
    copy_file "development.rb",         "config/push/development.rb"
    copy_file "staging.rb",             "config/push/staging.rb"
    copy_file "production.rb",          "config/push/production.rb"
    copy_file "feedback_processor.rb",  "lib/push/feedback_processor.rb"
  end
end