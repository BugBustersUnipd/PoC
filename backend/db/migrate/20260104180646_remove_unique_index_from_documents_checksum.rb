class RemoveUniqueIndexFromDocumentsChecksum < ActiveRecord::Migration[8.1]
  def change
    remove_index :documents, :checksum, if_exists: true
    add_index :documents, :checksum
  end
end
