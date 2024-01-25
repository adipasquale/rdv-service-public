class SetPrimaryKeyOnJoinTables < ActiveRecord::Migration[7.0]
  def up
    safety_assured do
      execute "ALTER TABLE motif_categories_territories ADD PRIMARY KEY (motif_category_id,territory_id);"
      execute "ALTER TABLE motifs_plage_ouvertures ADD PRIMARY KEY (motif_id,plage_ouverture_id);"

      add_index :motifs_plage_ouvertures, %i[motif_id plage_ouverture_id], unique: true, name: :index_motifs_plage_ouvertures_primary_keys
      remove_index :motifs_plage_ouvertures, :motif_id
      remove_index :motifs_plage_ouvertures, :plage_ouverture_id
    end
  end

  def down
    safety_assured do
      execute "ALTER TABLE motif_categories_territories DROP CONSTRAINT motif_categories_territories_pkey;"
      execute "ALTER TABLE motifs_plage_ouvertures DROP CONSTRAINT motifs_plage_ouvertures_pkey;"

      remove_index :motifs_plage_ouvertures, %i[motif_id plage_ouverture_id], name: :index_motifs_plage_ouvertures_primary_keys
      add_index :motifs_plage_ouvertures, :motif_id
      add_index :motifs_plage_ouvertures, :plage_ouverture_id
    end
  end
end
