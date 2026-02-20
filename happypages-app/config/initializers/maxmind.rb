mmdb_path = Rails.root.join("vendor", "maxmind", "GeoLite2-City.mmdb")

if File.exist?(mmdb_path)
  GEOIP_READER = MaxMind::GeoIP2::Reader.new(database: mmdb_path.to_s)
  Rails.logger.info "[MaxMind] GeoLite2-City database loaded"
else
  GEOIP_READER = nil
  Rails.logger.warn "[MaxMind] GeoLite2-City.mmdb not found at #{mmdb_path} — GeoIP lookups disabled"
end
