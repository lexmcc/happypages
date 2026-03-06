class Superadmin::OpsController < Superadmin::BaseController
  def index
    token = ENV.fetch("OPS_TOKEN")
    dashboard_url = ENV.fetch("OPS_DASHBOARD_URL", "http://localhost:3333")
    uri = URI("#{dashboard_url}/?embed=1&dashboardUrl=#{CGI.escape(dashboard_url)}")
    req = Net::HTTP::Get.new(uri)
    req["X-Ops-Token"] = token
    response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
    @dashboard_html = response.body
    @ops_token = token
    @dashboard_url = dashboard_url
  rescue => e
    @dashboard_html = "<div class='empty'>Dashboard unavailable: #{e.message}</div>"
    @ops_token = ""
    @dashboard_url = ""
  end
end
