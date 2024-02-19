ngx.say("Hello, from Nginx Openresty!")

local arg = ngx.req.get_uri_args()
local salt = arg.salt
if not salt then
    ngx.say("salt is nil")
    return
end
local t = ngx.time()
local dump = ngx.md5(ngx.localtime() .. salt)
--ngx.HTTP_OK
ngx.say("salt is ", salt, " time is ", t, " dump is ", dump)
