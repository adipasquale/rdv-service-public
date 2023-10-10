# frozen_string_literal: true

class AddTerritoryIdToServices < ActiveRecord::Migration[7.0]
  def change
    add_reference :services, :territory, foreign_key: true, index: true

    # Ce script a pour vocation de créer les services en spécifiant leur territoire, sur la base des services existant
    # Pour chaque service, identifier les territoires liés
    # Pour chaque service:
    #  - Pour chaque territoire du service:
    #     - Dupliquer le service dans le territoire
    #     - Mettre à jour tous les agents du territoire avec le nouveau service
    #     - Mettre à jour tous les motifs du territoire avec le nouveau service
    #
    # Supprimer tous les services sans TerritoryID

    services_by_agents = Service.joins(
      agents: { organisations: :territory }
    ).select(
      :id, :name, :short_name, "ARRAY_AGG(DISTINCT territories.id) as territories_ids"
    ).group(
      :id, :name, :short_name
    )
    migrate_services(services_by_agents, category: "agent")

    services_by_motifs = Service.joins(
      motifs: { organisation: :territory }
    ).select(
      :id, :name, :short_name, "ARRAY_AGG(DISTINCT territories.id) as territories_ids"
    ).group(
      :id, :name, :short_name
    )
    migrate_services(services_by_motifs, category: "motif")

    Service.where(territory_id: nil).destroy_all
  end

  def migrate_services(services, category:)
    Service.transaction do
      services.each do |service|
        service.territories_ids.each do |territory_id|
          new_service = service.dup
          new_service.territory_id = territory_id

          # This is to avoid issues with the unique validation on name and short_name columns
          service.update!(
            name: "old_#{category}_#{service.name}",
            short_name: "old_#{category}_#{service.short_name}"
          )
          new_service.save!

          Agent.joins(organisations: :territory).where(service_id: service.id, organisations: { territory_id: territory_id }).update_all(service_id: new_service.id)
          Motif.joins(organisation: :territory).where(service_id: service.id, organisation: { territory_id: territory_id }).update_all(service_id: new_service.id)
        end
      end
    end
  end
end
