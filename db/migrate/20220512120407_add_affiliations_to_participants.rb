class AddAffiliationsToParticipants < ActiveRecord::Migration[7.0]
  def change
    add_column :participants, :primary_affiliation, :string, after: :student_class_cache
    add_column :participants, :primary_affiliation_cache, :string, after: :primary_affiliation
    add_column :participants, :affiliation, :string, after: :primary_affiliation_cache
    add_column :participants, :affiliation_cache, :string, after: :affiliation
  end
end
