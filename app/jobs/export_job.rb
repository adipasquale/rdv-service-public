class ExportJob < ApplicationJob
  queue_as :exports

  private

  def hard_timeout
    5.minutes
  end
end
