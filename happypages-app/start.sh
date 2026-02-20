#!/bin/bash
set -e

# Download MaxMind GeoLite2 database if license key is set and file is missing
if [ -n "$MAXMIND_LICENSE_KEY" ] && [ ! -f vendor/maxmind/GeoLite2-City.mmdb ]; then
  echo "Downloading GeoLite2-City database..."
  mkdir -p vendor/maxmind
  curl -sSL "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-City&license_key=${MAXMIND_LICENSE_KEY}&suffix=tar.gz" \
    | tar xz --strip-components=1 -C vendor/maxmind --wildcards '*.mmdb'
  echo "GeoLite2-City.mmdb downloaded"
fi

echo "Preparing database..."
bundle exec rails db:prepare

echo "Backfilling missing shop slugs..."
bundle exec rails runner "Shop.where(slug: nil).find_each(&:save!)"

echo "Seeding prompt templates..."
bundle exec rails runner db/seeds/prompt_templates.rb

echo "Starting Rails server..."
exec bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000}
