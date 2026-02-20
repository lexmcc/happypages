module Analytics
  class EventIngester
    RESULT_OK = :ok
    RESULT_INVALID = :invalid
    RESULT_BOT = :bot
    RESULT_UNKNOWN_SITE = :unknown_site
    RESULT_DOMAIN_MISMATCH = :domain_mismatch

    MAX_STRING = 2048
    MAX_SHORT = 255
    MAX_EVENT_NAME = 64

    def call(raw_body:, user_agent:, remote_ip:)
      data = parse(raw_body)
      return RESULT_INVALID unless data

      token = data["t"]
      event_name = data["e"]
      visitor_id = data["v"]
      session_id = data["s"]

      return RESULT_INVALID if [token, event_name, visitor_id, session_id].any?(&:blank?)

      # Bot filtering
      return RESULT_BOT if ::CrawlerDetect.is_crawler?(user_agent)

      # Site lookup
      site = Analytics::Site.active.find_by(site_token: token)
      return RESULT_UNKNOWN_SITE unless site

      # Hostname validation — reject events from non-matching domains
      hostname = data["h"].to_s.downcase.sub(/\Awww\./, "")
      site_domain = site.domain.downcase.sub(/\Awww\./, "")
      unless hostname.empty? || hostname == site_domain || hostname.end_with?(".#{site_domain}")
        return RESULT_DOMAIN_MISMATCH
      end

      # UA parsing
      ua = ::DeviceDetector.new(user_agent)

      # GeoIP
      geo = geoip_lookup(remote_ip)

      # UTM params
      utms = data["u"] || {}

      Analytics::Event.create!(
        analytics_site_id: site.id,
        visitor_id: truncate(visitor_id, 32),
        session_id: truncate(session_id, 32),
        event_name: truncate(event_name, MAX_EVENT_NAME),
        pathname: truncate(data["p"], MAX_STRING),
        hostname: truncate(data["h"], MAX_SHORT),
        referrer: truncate(data["r"], MAX_STRING),
        utm_source: truncate(utms["utm_source"], MAX_SHORT),
        utm_medium: truncate(utms["utm_medium"], MAX_SHORT),
        utm_campaign: truncate(utms["utm_campaign"], MAX_SHORT),
        utm_term: truncate(utms["utm_term"], MAX_SHORT),
        utm_content: truncate(utms["utm_content"], MAX_SHORT),
        browser: truncate(ua.name, 64),
        browser_version: truncate(ua.full_version, 32),
        os: truncate(ua.os_name, 64),
        os_version: truncate(ua.os_full_version, 32),
        device_type: device_type(ua),
        country_code: geo&.dig(:country_code),
        region: truncate(geo&.dig(:region), 128),
        city: truncate(geo&.dig(:city), 128),
        referral_code: truncate(data["rc"], 64),
        properties: sanitize_properties(data["pr"]),
        occurred_at: Time.current
      )

      RESULT_OK
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn "[Analytics] Event validation failed: #{e.message}"
      RESULT_INVALID
    end

    private

    def parse(raw_body)
      JSON.parse(raw_body)
    rescue JSON::ParserError
      nil
    end

    def truncate(val, max)
      return nil if val.blank?
      val.to_s[0, max]
    end

    def device_type(ua)
      if ua.device_type
        ua.device_type[0, 16]
      else
        "desktop"
      end
    end

    def geoip_lookup(ip)
      return nil unless defined?(GEOIP_READER) && GEOIP_READER

      record = GEOIP_READER.city(ip)
      {
        country_code: record&.country&.iso_code,
        region: record&.most_specific_subdivision&.name,
        city: record&.city&.name
      }
    rescue MaxMind::GeoIP2::AddressNotFoundError
      nil
    rescue => e
      Rails.logger.warn "[Analytics] GeoIP error: #{e.message}"
      nil
    end

    def sanitize_properties(props)
      return {} unless props.is_a?(Hash)
      # Limit to 50 keys, truncate values
      props.first(50).to_h do |k, v|
        [k.to_s[0, 64], v.to_s[0, 256]]
      end
    end
  end
end
