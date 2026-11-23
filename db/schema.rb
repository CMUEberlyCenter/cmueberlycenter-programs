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

ActiveRecord::Schema[8.1].define(version: 2026_11_04_150000) do
  create_table "future_faculty_requirement_categories", force: :cascade do |t|
    t.string "key"
    t.string "label"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "future_faculty_requirements", force: :cascade do |t|
    t.string "key"
    t.string "label"
    t.integer "future_faculty_requirements_version_id"
    t.integer "future_faculty_requirement_category_id"
    t.string "activity_class"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["future_faculty_requirement_category_id"], name: "index_ff_requirements_on_ff_requirement_category_id"
    t.index ["future_faculty_requirements_version_id"], name: "index_ff_requirements_on_ff_requirements_version_id"
  end

  create_table "future_faculty_requirements_versions", force: :cascade do |t|
    t.string "key"
    t.string "label"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "participant_activities", force: :cascade do |t|
    t.integer "participant_id"
    t.string "type"
    t.integer "future_faculty_requirement_id"
    t.integer "status_id"
    t.string "course"
    t.string "title"
    t.string "description"
    t.integer "observer_id"
    t.integer "lead_consultant_id"
    t.date "completed_on"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "internal_notes"
    t.date "memo_completed_on"
    t.date "first_consultation_on"
    t.index ["first_consultation_on"], name: "index_participant_activities_on_first_consultation_on"
    t.index ["future_faculty_requirement_id"], name: "index_participant_activities_on_ff_requirement_id"
    t.index ["lead_consultant_id"], name: "index_participant_activities_on_lead_consultant_id"
    t.index ["observer_id"], name: "index_participant_activities_on_observer_id"
    t.index ["participant_id"], name: "index_participant_activities_on_participant_id"
    t.index ["status_id"], name: "index_participant_activities_on_status_id"
  end

  create_table "participant_activity_status_types", force: :cascade do |t|
    t.integer "future_faculty_requirement_id"
    t.string "key"
    t.string "label"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["future_faculty_requirement_id"], name: "fk_rails_136cc54ad1"
  end

  create_table "participants", force: :cascade do |t|
    t.string "andrewid"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "is_admin", default: false
    t.boolean "is_consultant", default: false
    t.string "name"
    t.string "name_archive"
    t.string "sortable_name"
    t.string "sortable_name_archive"
    t.text "dept"
    t.text "dept_archive"
    t.text "college"
    t.text "college_archive"
    t.string "student_class"
    t.string "student_class_archive"
    t.string "primary_affiliation"
    t.string "primary_affiliation_archive"
    t.string "affiliation"
    t.string "affiliation_archive"
    t.string "email"
    t.text "note"
    t.integer "future_faculty_enrollment_id"
    t.integer "future_faculty_progress_status_id"
    t.date "first_consultation_on"
    t.date "future_faculty_program_graduated_on"
    t.index ["future_faculty_enrollment_id"], name: "index_participants_on_future_faculty_enrollment_id"
    t.index ["future_faculty_progress_status_id"], name: "index_participants_on_future_faculty_progress_status_id"
  end

  create_table "progress_status_types", force: :cascade do |t|
    t.string "key"
    t.string "label"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "registration_attendance_status_types", force: :cascade do |t|
    t.string "key"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "label"
  end

  create_table "registration_waitlist_status_types", force: :cascade do |t|
    t.string "key"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "action_label"
  end

  create_table "registrations", force: :cascade do |t|
    t.integer "participant_id"
    t.integer "seminar_id"
    t.integer "waitlist_status_id"
    t.integer "attendance_status_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["attendance_status_id"], name: "index_registrations_on_attendance_status_id"
    t.index ["participant_id"], name: "index_registrations_on_participant_id"
    t.index ["seminar_id"], name: "index_registrations_on_seminar_id"
    t.index ["waitlist_status_id"], name: "index_registrations_on_waitlist_status_id"
  end

  create_table "seminar_status_types", force: :cascade do |t|
    t.string "key"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "seminar_tags", force: :cascade do |t|
    t.integer "seminar_id"
    t.string "value"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["seminar_id"], name: "index_seminar_tags_on_seminar_id"
  end

  create_table "seminars", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "start_at", precision: nil
    t.datetime "end_at", precision: nil
    t.integer "seminar_status_id"
    t.integer "maximum_capacity"
    t.integer "participants_confirmed_cache"
    t.string "location"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "confirmed_email_insert"
    t.text "pending_email_insert"
    t.boolean "is_async"
    t.boolean "enable_waitlist"
    t.index ["seminar_status_id"], name: "index_seminars_on_seminar_status_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "label"
    t.string "key"
    t.text "value"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  add_foreign_key "future_faculty_requirements", "future_faculty_requirement_categories"
  add_foreign_key "future_faculty_requirements", "future_faculty_requirements_versions"
  add_foreign_key "participant_activities", "future_faculty_requirements"
  add_foreign_key "participant_activities", "participant_activity_status_types", column: "status_id"
  add_foreign_key "participant_activities", "participants"
  add_foreign_key "participant_activities", "participants", column: "lead_consultant_id"
  add_foreign_key "participant_activity_status_types", "future_faculty_requirements"
  add_foreign_key "participants", "future_faculty_requirements_versions", column: "future_faculty_enrollment_id"
  add_foreign_key "participants", "progress_status_types", column: "future_faculty_progress_status_id"
end
