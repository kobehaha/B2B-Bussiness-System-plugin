
local cjson = require "cjson"
local http = require("socket.http")
local ltn12 = require("ltn12")

dyna_upstreams = {}


--curl -X PUT http://127.0.0.1:8500/v1/catalog/register -d '{ "Datacenter": "dc1", "Node": "tomcat", "Address": "127.0.0.1", "Service": {"Id": "127.0.0.1:8080", "Service": "item_work_tomcat", "tags":["dev"], "Port": 8080} }'

function dyna_upstreams.update_upstreams()
    local resp = {}
    http.request{
        url =
		    "http://127.0.0.1:8500/v1/catalog/service/item_work_tomcat",
	        sink = ltn12.sink.table(resp)
    }
    resp = table.contact(resp)
    resp = cjson.decode(resp)

    local upstreams = {{ip = "127.0.0.1"} , port = 1111 }
    for i, v in ipaires{resp} do
        upstreams[i + 1] = { ip = v.Address, port = v.ServicePort}
    end

    ngx.shared.upstream_list:set("item_work_tomcat", cjson.encode(upstreams))
end

function dyna_upstreams.get_upstreams()
    local upstreams_str = ngx.shared.upstream_list:get("item_work_tomcat")
end


--local _M = {
--    update_upstreams = update_upstreams,
--    get_upstreams = get_upstreams
--}

return dyna_upstreams

   
