class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.references :company, null: false, foreign_key: true
      t.string :status
      t.string :doc_type
      t.jsonb :ai_data
      t.string :checksum

      t.timestamps
    end

    add_index :documents, :checksum
    add_index :documents, [:company_id, :created_at]
  end
end
