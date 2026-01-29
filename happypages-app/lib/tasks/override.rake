namespace :override do
  desc "Process scheduled discount override start/end times"
  task check: :environment do
    OverrideSchedulerJob.perform_now
  end
end
