# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_16_171729) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "companies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.text "summary"
    t.string "title"
    t.bigint "tone_id", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_conversations_on_company_id"
    t.index ["tone_id"], name: "index_conversations_on_tone_id"
  end

  create_table "documents", force: :cascade do |t|
    t.jsonb "ai_data"
    t.string "checksum"
    t.bigint "company_id", default: 1, null: false
    t.datetime "created_at", null: false
    t.string "doc_type"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["checksum"], name: "index_documents_on_checksum"
    t.index ["company_id", "created_at"], name: "index_documents_on_company_id_and_created_at"
    t.index ["company_id"], name: "index_documents_on_company_id"
  end

  create_table "generated_images", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "conversation_id"
    t.datetime "created_at", null: false
    t.integer "height", null: false
    t.string "model_id", null: false
    t.text "prompt", null: false
    t.string "quality", default: "standard", null: false
    t.datetime "updated_at", null: false
    t.integer "width", null: false
    t.index ["company_id", "created_at"], name: "index_generated_images_on_company_id_and_created_at"
    t.index ["company_id"], name: "index_generated_images_on_company_id"
    t.index ["conversation_id"], name: "index_generated_images_on_conversation_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "content", null: false
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["created_at"], name: "index_messages_on_created_at"
  end

  create_table "tones", force: :cascade do |t|
    t.bigint "company_id"
    t.datetime "created_at", null: false
    t.text "instructions"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_tones_on_company_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "conversations", "companies"
  add_foreign_key "conversations", "tones"
  add_foreign_key "documents", "companies"
  add_foreign_key "generated_images", "companies"
  add_foreign_key "generated_images", "conversations"
  add_foreign_key "messages", "conversations"
  add_foreign_key "tones", "companies"
end
