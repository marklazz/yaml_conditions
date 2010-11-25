ActiveRecord::Schema.define do
  create_table :jobs do |t|
    t.string :name
    t.string :desc
    t.text   :data
    t.timestamps
  end

  create_table :users do |t|
    t.string  :name
    t.string  :address
    t.text    :details
    t.timestamps
  end

  create_table :user_datas do |t|
    t.integer :social_number
    t.string  :title
    t.integer :age
    t.integer :period_id
  end

  create_table :periods do |t|
    t.string  :year
  end

  create_table :priorities do |t|
    t.integer :job_id
    t.integer :value
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
end
