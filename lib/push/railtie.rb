require 'push'
require 'rails'
module Push
  class Railtie < Rails::Railtie
    railtie_name :push

    rake_tasks do
      load 'tasks/push_tasks.rake'
    end
  end
end