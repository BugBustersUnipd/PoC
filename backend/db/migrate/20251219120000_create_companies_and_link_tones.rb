class CreateCompaniesAndLinkTones < ActiveRecord::Migration[8.1]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps
    end

    add_reference :tones, :company, null: true, foreign_key: true
  end
end
