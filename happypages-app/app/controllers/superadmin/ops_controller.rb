class Superadmin::OpsController < Superadmin::BaseController
  def index
    token = ENV["OPS_TOKEN"]
    unless token
      @dashboard_html = nil
      return
    end

    dashboard_url = ENV.fetch("OPS_DASHBOARD_URL", "http://localhost:3333")
    uri = URI("#{dashboard_url}/?embed=1&dashboardUrl=#{CGI.escape(dashboard_url)}")
    req = Net::HTTP::Get.new(uri)
    req["X-Ops-Token"] = token
    response = Net::HTTP.start(uri.hostname, uri.port, read_timeout: 5, open_timeout: 3) { |http| http.request(req) }
    @dashboard_html = response.body
    @ops_token = token
    @dashboard_url = dashboard_url
  rescue => e
    @dashboard_html = "<div class='text-center py-16'><p class='text-ops-text-secondary'>Dashboard unavailable</p><p class='text-sm text-ops-text-tertiary mt-2'>#{ERB::Util.html_escape(e.message)}</p></div>"
    @ops_token = ""
    @dashboard_url = ""
  end
end
