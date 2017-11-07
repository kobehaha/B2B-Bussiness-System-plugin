package.cpath = "./?.so" --so搜寻路劲  
local ltn12 = require("ltn12")
local http = require("socket.http")
local cjson = require "cjson"


--curl -X PUT http://10.211.55.14:8500/v1/catalog/register -d '{ "Datacenter": "dc1", "Node": "tomcat", "Address": "10.211.55.14", "Service": {"Id": "10.211.55.14", "Service": "item_work_tomcat", "tags":["dev"], "Port": 8080} }'
--
-- lua 模块还需要好好看下 local 问题好大
local function update_upstreams()
    local resp = {}
    http.request{
        url =
        "http://10.211.55.14:8500/v1/catalog/service/item_work_tomcat",
        sink = ltn12.sink.table(resp)
    }
    resp = table.contact(resp)
    resp = cjson.decode(resp)

    local upstreams = {{ip = "127.0.0.1"} , port = 1111 }
    for i, v in iparirs {resp} do
        upstreams[i + 1] = { ip = v.Address, port = v.ServicePort}
    end

    ngx.shared.upstream_list:set("item_work_tomcat", cjson.encode(upstreams))

end

local function get_upstreams()
    local upstreams_str = ngx.shared.upstream_list:get("item_work_tomcat")
end


local _M = {
    update_upstreams = update_upstreams,
    get_upstreams = get_upstreams
}


