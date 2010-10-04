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
    t.integer :age
    t.timestamps
  end

  create_table :priorities do |t|
    t.integer :job_id
    t.integer :value
  end
end
