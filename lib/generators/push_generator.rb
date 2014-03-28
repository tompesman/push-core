class PushGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  source_root File.expand_path('../templates', __FILE__)

  def self.next_migration_number(path)
    Time.now.utc.strftime("%Y%m%d%H%M%S")
  end

  def copy_migration
    migration_dir = File.expand_path("db/migrate")

    Dir["#{self.class.source_root}/migrations/*.rb"].sort.each do |migration_template|
      migration_name = File.basename( migration_template, '.rb' )

      if !self.class.migration_exists?(migration_dir, migration_name)
        migration_template migration_template, "db/migrate/#{migration_name}.rb"
      end
    end
  end

  def copy_config
    unless File.exists? "lib/push/feedback_processor.rb"
      copy_file "feedback_processor.rb",  "lib/push/feedback_processor.rb"
    end
  end
end