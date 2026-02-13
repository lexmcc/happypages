#!/bin/bash
set -e

echo "Preparing database..."
bundle exec rails db:prepare

echo "Backfilling missing shop slugs..."
bundle exec rails runner "Shop.where(slug: nil).find_each(&:save!)"

echo "Seeding prompt templates..."
bundle exec rails runner db/seeds/prompt_templates.rb

echo "Starting Rails server..."
exec bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000}
