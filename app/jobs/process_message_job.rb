class ProcessMessageJob < ApplicationJob
  queue_as :default

  def perform(message)
    sleep(5)
    logger.info "Processing message #{message.id}"
    message.processed = true
    message.save!
  end
end
