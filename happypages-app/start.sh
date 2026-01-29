#!/bin/bash
set -e

echo "Checking database connection..."
bundle exec rails runner "puts 'Connected to: ' + ActiveRecord::Base.connection.current_database"

echo "Checking for existing tables..."
TABLE_COUNT=$(bundle exec rails runner "puts ActiveRecord::Base.connection.tables.count")
echo "Found $TABLE_COUNT tables"

if [ "$TABLE_COUNT" -eq "0" ]; then
  echo "No tables found. Loading schema..."
  bundle exec rails db:schema:load
  echo "Schema loaded. Running migrations..."
  bundle exec rails db:migrate
else
  echo "Tables exist. Running migrations..."
  bundle exec rails db:migrate
fi

echo "Backfilling missing shop slugs..."
bundle exec rails runner "Shop.where(slug: nil).find_each { |s| s.save! }"

echo "Starting Rails server..."
exec bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000}
