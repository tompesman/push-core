# Push Rake Tasks
namespace :push do
  desc "Delete all push messages and feedback older than 7 days or DAYS=x if defined (where x is an integer)"
  task :clean => :environment do
    days = ENV["DAYS"].to_i || 7
    Push::Feedback.where("created_at < ?", days.days.ago).delete_all
    Push::Message.where("created_at < ?", days.days.ago).delete_all
  end
end
