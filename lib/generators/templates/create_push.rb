class CreatePush < ActiveRecord::Migration
  def self.up
    create_table :push_messages do |t|
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
      t.string    :device,                :null => false
      t.string    :type,                  :null => false
      t.string    :follow_up,             :null => false
      t.timestamp :failed_at,             :null => false
      t.text      :properties,            :null => true
      t.timestamps
    end

    add_index :push_feedback, :device
  end

  def self.down
    drop_table :push_feedback
    drop_table :push_messages
  end
end
