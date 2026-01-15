class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :company, null: false, foreign_key: true
      t.references :tone, null: false, foreign_key: true

      t.timestamps
    end
  end
end
