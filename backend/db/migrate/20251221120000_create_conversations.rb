class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :company, null: false, foreign_key: true
      t.string :title
      t.text :summary

      t.timestamps
    end
  end
end
