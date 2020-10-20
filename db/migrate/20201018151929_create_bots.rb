class CreateBots < ActiveRecord::Migration[6.0]
  def change
    create_table :bots do |t|
      t.string :username
      t.string :description
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
