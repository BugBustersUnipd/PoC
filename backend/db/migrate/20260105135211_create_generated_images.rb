class CreateGeneratedImages < ActiveRecord::Migration[8.1]
  def change
    create_table :generated_images do |t|
      t.references :company, null: false, foreign_key: true
      t.references :conversation, null: true, foreign_key: true
      t.text :prompt, null: false
      t.integer :width, null: false
      t.integer :height, null: false
      t.string :quality, null: false, default: "standard"
      t.string :model_id, null: false

      t.timestamps
    end

    add_index :generated_images, [:company_id, :created_at]
  end
end
