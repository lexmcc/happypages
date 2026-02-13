Rack::Attack.throttle("api/referrals/create", limit: 500, period: 60) do |req|
  req.ip if req.path == "/api/referrals" && req.post?
end

Rack::Attack.throttle("superadmin/login", limit: 5, period: 60) do |req|
  req.ip if req.path == "/superadmin/login" && req.post?
end

Rack::Attack.throttle("admin/image_generations", limit: 5, period: 300) do |req|
  req.ip if req.path == "/admin/image_generations" && req.post?
end
