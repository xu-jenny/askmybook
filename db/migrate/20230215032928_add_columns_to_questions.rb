class AddColumnsToQuestions < ActiveRecord::Migration[7.0]
  def change
    add_column :questions, :embedding, :text, array: true, default: []
    add_column :questions, :similiarq, :text
  end
end
