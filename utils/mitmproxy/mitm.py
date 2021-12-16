import json
import json
import os
import random
import re
import re
from time import sleep
from time import sleep

from mitmproxy import ctx
from mitmproxy import ctx
from mitmproxy import http
from ruamel.yaml import YAML

HOME_DIR = "./"
DATA_DIR = HOME_DIR + "responses/"
CONFIG_FILE = HOME_DIR + "mitm.yaml"

config_modified_at = None
map_local = None
delay = None


def request(flow: http.HTTPFlow) -> None:
    reload_config_if_updated()
    if delay is not None and delay > 0:
        delay_in_ms = delay / 1000
        ctx.log.info("Make response delay {} ms for request {}".format(delay, get_request_url_suffix(flow)))
        sleep(delay_in_ms)


def response(flow: http.HTTPFlow) -> None:
    reload_config_if_updated()
    if map_local is None:
        return None

    url = flow.request.url

    filename = map_local["urls"][url]
    if filename is None:
        return None

    filename += ".json"
    json_file = DATA_DIR + str(filename)
    if not is_file_not_empty(json_file):
        return None

    data = json.load(open(json_file))
    if data is None:
        return None

    status = get_json_value(data, "mitm_status", map_local["status"])
    headers = get_json_value(data, "mitm_headers", map_local["headers"])
    content = json.dumps(get_json_value(data, "mitm_content", data))

    ctx.log.info("Use mock file {} for request {}, status {}".format(filename, get_request_url_suffix(flow), status))
    flow.response = http.Response.make(status, content, headers)


def get_request_url_suffix(flow):
    return "..." + flow.request.url[-25:]


def get_json_value(data, key, default_value):
    if key in data:
        return data[key]
    else:
        return default_value


def is_file_not_empty(path):
    return os.path.isfile(path) and os.path.exists(path) and os.path.getsize(path) > 0


def reload_config_if_updated():
    global config_modified_at, map_local, delay
    timestamp = os.path.getmtime(CONFIG_FILE)
    if timestamp != config_modified_at:
        config_modified_at = timestamp
        if is_file_not_empty(CONFIG_FILE):
            yaml = YAML(typ="safe").load(open(CONFIG_FILE))
            map_local = yaml["map_local"]
            delay = yaml["delay"]
            ctx.log.info("Load configuration file " + CONFIG_FILE)
            return None
        else:
            ctx.log.error("Error read file " + CONFIG_FILE)
            return None
