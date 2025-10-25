--- Created by kuncheng.
--- DateTime: 2024/1/24 11:19 AM
---
local core = require("apisix.core")
local jwt = require("resty.jwt")
local ngx = ngx
local httpc = require("resty.http").new()
local string_format = string.format
local req_read_body = ngx.req.read_body
local req_get_body_data = ngx.req.get_body_data
-- 防止热点api冲击
local permission_cache = core.lrucache.new({
    type = "plugin",
    ttl = 10,
    count = 10000,
})

local lrucache = core.lrucache.new({
    type = "plugin",
    count = 10000,
    ttl = 5 * 60,
})
local json = core.json
local auth_header_key = "X-JiuZhou-Authorization"
local auth_secret = "^chen|tian|zhen$"
local user_info_key1 = "X-JiuZhou-Auth-Info"
local user_info_key2 = "user"
local plugin_name = "jiuzhou-rbac"
local log = core.log
local permission_addr = "172.16.179.166"
local permission_port = 8010
local version = "2.0.3"
local schema = {
    type = "object",
    properties = {
        -- 白名单不检查权限直接过
        white_list = {
            type = "array",
            minItems = 1,
            items = {
                type = "string"
            }
        }
    }
}
local metadata_schema = {}
local _M = {
    version = version,
    name = plugin_name,
    schema = schema,
    priority = 499,
    metadata_schema = metadata_schema,
}

--- 获取用户信息
--- @overload fun(token:string, user_id:number, method:string, uri:string): table, string
--- @param user_id number
--- @param method string
--- @param uri string
--- @return table,string | nil,nil
local function send_auth(user_id, method, uri)
    httpc:set_timeout(5 * 1000) -- 设置连接、发送、读取的总超时时间
    -- 连接到指定主机
    local ok, err = httpc:connect(permission_addr, permission_port)
    if not ok then
        log.error("Failed to connect to host: ", err)
        return nil, err
    end
    -- 构造请求体
    local body = {
        user_id = user_id,
        method = method,
        path = uri,
    }

    -- 将请求体转换为 JSON 字符串
    local body_json = json.encode(body)

    -- 发起 HTTP 请求
    local res
    res, err = httpc:request({
        method = "POST",
        path = "/v1/user/route/app",
        body = body_json, -- 使用 JSON 字符串作为请求体
        headers = {
            ["Content-Type"] = "application/json",
        }
    })
    if not res then
        log.error("Failed to send data: ", err)
        httpc:close()
        return nil, err
    end

    -- 读取响应体
    local res_body, read_err = res:read_body()
    if read_err then
        log.error("Failed to read response body: ", read_err)
        httpc:close()
        return nil, read_err
    end

    -- 使用 keepalive 以便重用连接
    ok, err = httpc:set_keepalive(60000, 10)
    if not ok then
        log.error("Failed to set keepalive: ", err)
        httpc:close()
        return nil, err
    end

    return {
        status = res.status,
        body = res_body
    }, nil
end

--检查配置文件
function _M.check_schema(conf, schema_type)
    if schema_type == core.schema.TYPE_METADATA then
        return core.schema.check(metadata_schema, conf)
    end
    return core.schema.check(schema, conf)
end

--- This function returns `table`.
--- @param token string
--- @return table|nil
local function verify_jwt(token)
    local jwt_obj = jwt:verify(auth_secret, token)
    if not jwt_obj["verified"] then
        return nil
    end
    return jwt_obj.payload
end

--- response
--- 如果返回的是一个table就按照table的格式输出
--- 如果返回的是一个string就按照msg = msg的格式输出
--- @overload fun(code:number, msg:string):number, table
--- @param code number
--- @param msg string|table
--- @return number, table
local function response(code, msg)
    if type(msg) == "string" then
        msg = { msg = msg, code = code }
    end
    -- 认证需要这种格式
    if code == ngx.HTTP_UNAUTHORIZED then
        msg = { msg = "token is invalid", code = "StatusUnauthorized", status = ngx.HTTP_UNAUTHORIZED }
    end
    return code, msg
end

--- 处理请求
--- @overload fun(conf:table, ctx:table):number
--- @param conf table
--- @param ctx table
--- @return number,table | number, void | void | number, string
function _M.rewrite(conf, ctx)
    local uri = core.request.get_uri(ctx)
    --从conf获取白名单路由
    if conf.white_list then
        for _, v in ipairs(conf.white_list) do
            if uri == v then
                return
            end
        end
    end
    --解析jwt
    local token = core.request.header(ctx, auth_header_key)
    if not token then
        -- 没有认证
        return response(ngx.HTTP_UNAUTHORIZED)
    end
    local auth_data = core.lrucache.plugin_ctx(lrucache, ctx, token, verify_jwt, token)
    if not auth_data then
        return response(ngx.HTTP_UNAUTHORIZED)
    end
    local payload, err
    payload, err = json.encode(auth_data)
    if err then
        log.error("json encode error: ", err)
        return response(ngx.HTTP_INTERNAL_SERVER_ERROR, err)
    end
    ctx.var.auth_data = payload
    --添加请求头
    core.request.add_header(user_info_key1, payload)
    core.request.add_header(user_info_key2, payload)
    local method = core.request.get_method()
    req_read_body()
    local post_body
    post_body = req_get_body_data()
    local req_post_body = ""
    if post_body ~= nil then
        req_post_body = post_body:gsub("%s+", ""):gsub("[\n\r]+", "")
    end
    ctx.var.req_post_body = req_post_body
    local user_id
    user_id = auth_data.user_id
    local httpc_res
    --httpc_res, err = send_auth(user_id, method, uri)
    httpc_res, err = core.lrucache.plugin_ctx(permission_cache, ctx, string_format("%d:%s:%s", user_id, method, uri), send_auth, user_id, method, uri)
    if err then
        return response(ngx.HTTP_INTERNAL_SERVER_ERROR, err)
    end

    if httpc_res.status ~= ngx.HTTP_OK then
        return httpc_res.status, httpc_res.body
    end
    return
end

--- 发送认证请求
--- @overload  fun(conf:table, ctx:table):void
--- @param conf table
--- @param ctx table
--- @return void
function _M.header_filter(conf, ctx)
    core.response.add_header("Content-Type", "application/json")
    core.response.add_header("X-JiuZhou-Proxy", version)
    core.response.add_header("X-Developer", "ckallcloud@foxmail.com")
    core.response.add_header("X-Developer-Auth", "chengkun")
end

-- 记录日志
--- @overload fun(conf:table, ctx:table):void
--- @param conf table
--- @param ctx table
--- @return void
function _M.log(conf, ctx)
    local scheme = core.request.get_scheme(ctx)
    local method = core.request.get_method()
    local host = core.request.get_host(ctx)
    local uri = core.request.get_uri(ctx)
    local get_args = core.request.get_args(ctx)
    local url = string_format("%s://$s%s%s", scheme, host, uri, get_args)
    local jwt_auth = ctx.var.auth_data
    local route_id = ctx.var.route_id
    local req_post_body = ctx.var.req_post_body
    if not jwt_auth then
        jwt_auth = "no auth jwt"
    end
    -- 这里还是记录普通的日志, 发送kafka,啥的还是打通其它扩展来完成,不然太麻烦了,也太重了
    log.error(string_format(
        'jiuzhou plugins rbac log method: "%s" Host: "%s" Uri: "%s" post_body2: "%s" jwt_obj: "%s" route_id: %d',
        method, host, url, req_post_body, jwt_auth, route_id
    ))
    return
end

-- 想在这里触发刷新权限,想想挺费内存的容我再想想
local function refresh()
    return 200, { msg = "tmp2" }
end

-- module interface for export public api
function _M.api()
    return {
        {
            methods = { "POST" },
            uri = "/x/gateway/jiuzhou_rbac/refresh",
            handler = refresh,
        }
    }
end

return _M
