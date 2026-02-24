Rack::Attack.throttle("api/referrals/create", limit: 500, period: 60) do |req|
  req.ip if req.path == "/api/referrals" && req.post?
end

Rack::Attack.throttle("sessions/login", limit: 5, period: 60) do |req|
  req.ip if req.path == "/login" && req.post?
end

Rack::Attack.throttle("invites/accept", limit: 5, period: 60) do |req|
  req.ip if req.path.start_with?("/invite/") && req.patch?
end

Rack::Attack.throttle("superadmin/login", limit: 5, period: 60) do |req|
  req.ip if req.path == "/superadmin/login" && req.post?
end

Rack::Attack.throttle("admin/image_generations", limit: 5, period: 300) do |req|
  req.ip if req.path == "/admin/image_generations" && req.post?
end

Rack::Attack.throttle("analytics/collect", limit: 1000, period: 60) do |req|
  req.ip if req.path == "/collect" && req.post?
end

Rack::Attack.throttle("specs/message", limit: 1, period: 3) do |req|
  if req.path.match?(%r{\A/admin/specs/\d+/message\z}) && req.post?
    req.path
  end
end

Rack::Attack.throttle("specs/guest/message", limit: 1, period: 3) do |req|
  req.path[%r{^/specs/session/(.+)/message$}, 1] if req.post?
end
