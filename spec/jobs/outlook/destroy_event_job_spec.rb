# frozen_string_literal: true

require "rails_helper"

RSpec.describe Outlook::DestroyEventJob, type: :job do
  let(:organisation) { create(:organisation, id: 10) }
  let(:motif) { create(:motif, name: "Super Motif", location_type: :phone) }
  # We need to create a fake agent to initialize a RDV as they have a validation on agents which prevents us to control the data in its AgentsRdv
  let(:fake_agent) { create(:agent) }
  let(:agent) { create(:agent, microsoft_graph_token: "token") }
  let(:rdv) { create(:rdv, id: 20, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 11h00"), duration_in_min: 30, agents: [fake_agent]) }
  let(:agents_rdv) { create(:agents_rdv, id: 12, rdv: rdv, agent: agent, outlook_id: "super_id") }

  context "when the event is destroyed" do
    before do
      stub_request(:post, "https://login.microsoftonline.com/common/oauth2/v2.0/token")
        .to_return(status: 200, body: { access_token: "token" }.to_json, headers: {})
      stub_request(:delete, "https://graph.microsoft.com/v1.0/me/Events/super_id")
        .with(
          headers: { "Accept" => "application/json", "Authorization" => "Bearer token", "Content-Type" => "application/json", "Expect" => "", "Return-Client-Request-Id" => "true",
                     "User-Agent" => "RDVSolidarites", }
        )
        .to_return(status: 204, body: "", headers: {})

      allow(Sentry).to receive(:capture_message)

      described_class.perform_now(agents_rdv)
    end

    it "updates the outlook_id" do
      expect(agents_rdv.outlook_id).to eq(nil)

      expect(Sentry).not_to have_received(:capture_message)
    end
  end

  context "when the event cannot be destroyed" do
    before do
      stub_request(:post, "https://login.microsoftonline.com/common/oauth2/v2.0/token")
        .to_return(status: 200, body: { access_token: "token" }.to_json, headers: {})
      stub_request(:delete, "https://graph.microsoft.com/v1.0/me/Events/super_id")
        .with(
          headers: { "Accept" => "application/json", "Authorization" => "Bearer token", "Content-Type" => "application/json", "Expect" => "", "Return-Client-Request-Id" => "true",
                     "User-Agent" => "RDVSolidarites", }
        )
        .to_return(status: 404, body: { error: { code: "TerribleError", message: "Quelle terrible erreur" } }.to_json, headers: {})

      allow(Sentry).to receive(:capture_message)

      described_class.perform_now(agents_rdv)
    end

    it "does not update the outlook_id" do
      expect(agents_rdv.outlook_id).to eq("super_id")

      expect(Sentry).to have_received(:capture_message).with("Outlook API error for AgentsRdv 12: Quelle terrible erreur")
    end
  end
end