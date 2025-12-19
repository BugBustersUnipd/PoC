class CreateTones < ActiveRecord::Migration[8.1]
  def change
    create_table :tones do |t|
      t.string :name
      t.text :instructions

      t.timestamps
    end
  end
end
