class CreateDonotcallphone < ActiveRecord::Migration
  def up
    create_table :do_not_call_phones, id: false do |t|
      t.text :number
    end
    execute "ALTER TABLE do_not_call_phones ADD PRIMARY KEY (number);"
    add_index(:do_not_call_phones, :number, using: 'hash')
  end
  def down
    drop_table :do_not_call_phones
  end
end
