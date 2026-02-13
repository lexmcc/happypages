class CreateGenerationLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :generation_logs do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :surface, null: false
      t.string :model_used
      t.text :prompt_text
      t.jsonb :input_context, default: {}
      t.string :output_image_url
      t.integer :quality_score
      t.integer :cost_cents
      t.boolean :is_retry, default: false
      t.timestamps
    end

    add_index :generation_logs, [:shop_id, :surface]
    add_index :generation_logs, :created_at
  end
end
