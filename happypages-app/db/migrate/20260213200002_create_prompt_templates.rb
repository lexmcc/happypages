class CreatePromptTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :prompt_templates do |t|
      t.string :key, null: false
      t.string :category
      t.string :surface, null: false
      t.text :template_text, null: false
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :prompt_templates, :key, unique: true
    add_index :prompt_templates, [ :surface, :category ]
  end
end
