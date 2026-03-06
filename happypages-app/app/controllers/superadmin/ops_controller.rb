class Superadmin::OpsController < Superadmin::BaseController
  def index
    dashboard_url = ENV.fetch("OPS_DASHBOARD_URL", "http://localhost:3333")
    uri = URI("#{dashboard_url}/?embed=1&dashboardUrl=#{CGI.escape(dashboard_url)}")
    response = Net::HTTP.start(uri.hostname, uri.port, read_timeout: 5, open_timeout: 3) { |http| http.request(Net::HTTP::Get.new(uri)) }
    @dashboard_html = response.body
    @dashboard_url = dashboard_url
  rescue => e
    @dashboard_html = nil
  end
end
