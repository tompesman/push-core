class CreatePush < ActiveRecord::Migration
  def self.up
    create_table :push_configurations do |t|
      t.string    :type,                  :null => false
      t.string    :app,                   :null => false
      t.text      :properties,            :null => true
      t.boolean   :enabled,               :null => false, :default => false
      t.integer   :connections,           :null => false, :default => 1
      t.timestamps
    end

    create_table :push_messages do |t|
      t.string    :app,                   :null => false
      t.string    :device,                :null => false
      t.string    :type,                  :null => false
      t.text      :properties,            :null => true
      t.boolean   :delivered,             :null => false, :default => false
      t.timestamp :delivered_at,          :null => true
      t.boolean   :failed,                :null => false, :default => false
      t.timestamp :failed_at,             :null => true
      t.integer   :error_code,            :null => true
      t.string    :error_description,     :null => true
      t.timestamp :deliver_after,         :null => true
      t.timestamps
    end

    add_index :push_messages, [:delivered, :failed, :deliver_after]

    create_table :push_feedback do |t|
      t.string    :app,                   :null => false
      t.string    :device,                :null => false
      t.string    :type,                  :null => false
      t.string    :follow_up,             :null => false
      t.timestamp :failed_at,             :null => false
      t.boolean   :processed,             :null => false, :default => false
      t.timestamp :processed_at,          :null => true
      t.text      :properties,            :null => true
      t.timestamps
    end

    add_index :push_feedback, :processed
  end

  def self.down
    drop_table :push_feedback
    drop_table :push_messages
    drop_table :push_configurations
  end
end
