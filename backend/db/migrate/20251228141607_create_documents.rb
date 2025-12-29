class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.string :status
      t.string :doc_type
      t.jsonb :ai_data

      t.timestamps
    end
  end
end
