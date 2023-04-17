# frozen_string_literal: true

describe RdvBlueprint do
  subject(:json) { JSON.parse(rendered) }

  let(:rendered) { described_class.render(rdv, { root: :rdv }) }
  let(:rdv) { build(:rdv) }

  describe "status" do
    let(:motif) { create(:motif) }
    let(:rdv) { build(:rdv, status: "revoked", motif: motif) }

    it do
      expect(json.dig("rdv", "status")).to eq("revoked")
      expect(json.dig("rdv", "motif", "motif_category", "id")).to eq(MotifCategory.first.id)
    end
  end

  it "shows rdv collectif fields" do
    expect(json["rdv"]).to include({
                                     "collectif" => false,
                                     "context" => nil,
                                     "created_by" => "agent",
                                     "duration_in_min" => 45,
                                     "max_participants_count" => nil,
                                     "name" => nil,
                                   })
  end

  describe "users (DEPRECATED)" do
    let(:user) { build(:user, first_name: "Jean") }
    let(:rdv) { build(:rdv, users: [user]) }

    it do
      expect(json.dig("rdv", "users").first["first_name"]).to eq("Jean")
    end
  end

  describe "rdvs_users contains user" do
    let(:user) { build(:user, first_name: "Jean") }
    let(:rdv) { create(:rdv, status: "seen", users: [user]) }

    it do
      expect(json.dig("rdv", "rdvs_users").first["status"]).to eq("seen")
      expect(json.dig("rdv", "rdvs_users").first["user"]["first_name"]).to eq("Jean")
    end
  end

  describe "web_url" do
    let(:organisation) { create(:organisation) }
    let(:rdv) { create(:rdv, organisation: organisation) }

    it do
      expect(json.dig("rdv", "web_url")).to eq("http://www.rdv-solidarites-test.localhost/admin/organisations/#{organisation.id}/rdvs/#{rdv.id}")
    end
  end
end
