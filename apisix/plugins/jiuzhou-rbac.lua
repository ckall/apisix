---
--- Generated by Luanalysis
--- Created by kuncheng.
--- DateTime: 2024/1/24 11:19 AM
---
local core = require("apisix.core")
local jwt = require("resty.jwt")
--local mysql = require("resty.mysql")
local http = require("resty.http")
local json = core.json
local auth_header_key = "X-JiuZhou-Authorization"
local auth_secret = "^chen|tian|zhen$"
local user_info_key1 = "X-JiuZhou-Auth-Info"
local user_info_key2 = "user"
local plugin_name = "jiuzhou-rbac"
local method_post = "POST"
local path = "http://172.16.179.166:8010/v1/user/route/app"
local log = core.log
local version = "2.0"
local schema = {}
local metadata_schema = {}
local ngx = ngx
local _M = {
    version = version,
    name = plugin_name,
    schema = schema,
    priority = 91,
    metadata_schema = metadata_schema,
}

--检查配置文件
function _M.check_schema(conf, schema_type)
    if schema_type == core.schema.TYPE_METADATA then
        return core.schema.check(metadata_schema, conf)
    end
    return core.schema.check(schema, conf)
end

--处理请求
function _M.rewrite(conf, ctx)
    --解析jwt
    local auth_header = core.request.header(ctx, auth_header_key)
    local jwt_obj = jwt:verify(auth_secret, auth_header)
    local scheme = core.request.get_scheme(ctx)
    local host = core.request.get_host(ctx)
    local args = core.request.get_uri_args(ctx)
    local post_body = core.request.get_post_args(ctx)
    local post_body1 = core.request.get_body(0, ctx)
    local post_body2 = core.request.get_body(1024, ctx)
    core.response.add_header("Content-Type", "application/json")
    core.response.add_header("X-JiuZhou-Proxy", version)
    core.response.add_header("Server", "ck_openresty")
    local uri = ctx.var.uri
    local get_args = ""
    if ctx.var.args then
        get_args = "?" .. ctx.var.args
    end
    local url = scheme .. "://" .. host .. uri .. get_args
    if not jwt_obj["verified"] then
        return 401,
            {
                message = "Missing authorization in request",
                code = "StatusUnauthorized",
                status = 401,
                --metadata = {
                --    jwt_obj = jwt_obj,
                --    scheme = scheme,
                --    host = host,
                --    args = json.encode(args, true),
                --    post_body = json.encode(post_body),
                --    --uri = uri,
                --    post_body1 = post_body1,
                --    post_body2 = post_body2,
                --    post_body = post_body,
                --    url = url,
                --    args = ctx.var.args,
                --}
            }
    end
    core.response.add_header(user_info_key1, jwt_obj.payload)
    core.response.add_header(user_info_key2, jwt_obj.payload)
    local user_id = jwt_obj.payload.user_id
    local request_method = core.request.get_method(ctx)
    local http_link = http.new()
    local request_body = json.encode({
        user_id = user_id,
        method = request_method,
        path = uri,
    }, true)
    local res, err = http_link:request_uri(path, {
        method = method_post,
        body = request_body,
        headers = {
            ["Content-Type"] = "application/json",
        }
    })
    if not res then
        log.error(ngx.ERR, "Failed to make request: ", err)
        return 500, { message = "request err1: " .. err, data = nil, code = 500, request = request_body }
    end
    if res.status ~= 200 then
        log.error(ngx.ERR, "Failed to make request: ", res.body)
        return res.status, res.body
    end
    local body
    body, err = json.decode(res.body)
    if body.status ~= 200 then
        return res.status, body
    end
    -- 创建http请求
    return
end


local function my_timer_handler(premature, arg)
    if not premature then
        -- 在这里编写定时任务的具体逻辑
        log.error(ngx.INFO, "定时任务执行了，参数为: ", arg)
    end
end

-- 记录日志
function _M.log(conf, ctx)
    ---- 获取url+path地址+query参数
    local scheme = core.request.get_scheme(ctx)
    local host = core.request.get_host(ctx)
    local body = core.request.get_post_args(ctx)
    if not body then
        body = ""
    end
    body = json.encode(body, true)
    local uri = ctx.var.uri
    local get_args = ""
    if ctx.var.args then
        get_args = "?" .. ctx.var.args
    end
    local url_path = uri .. get_args
    log.error(
        "jiuzhou plugins rbac log",
        " Scheme:", "\"" .. scheme .. "\"",
        " Host:", "\"" .. host .. "\"",
        " Uri:", "\"" .. url_path .. "\"",
        " Body:", "\"" .. body .. "\""
    )
    return
end

return _M


