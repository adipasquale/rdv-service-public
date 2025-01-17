class TriggerWebhookJob < ApplicationJob
  queue_as :trigger_webhook

  self.log_arguments = false

  def perform(webhook_endpoint_id)
    @webhook_endpoint = WebhookEndpoint.find(webhook_endpoint_id)
    @webhook_endpoint.trigger_for_all_subscribed_resources
  end

  private

  def hard_timeout
    10.minutes
  end
end
