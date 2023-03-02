import json
import os
import re
from mitmproxy import ctx
from mitmproxy import http
from ruamel.yaml import YAML
from time import sleep

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

    try_mock_response(flow)


def try_mock_response(flow: http.HTTPFlow):
    if map_local is None:
        return None

    url = flow.request.url

    filename = get_name_of_mocked_file(url, flow.request.method)
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
    content = get_json_dumps(data, "mitm_content")

    if content is None:
        ctx.log.warn("Use mock w/o content for request {}, status {}".format(get_request_url_suffix(flow), status))
        flow.response = http.Response.make(status)
    else:
        ctx.log.warn(
            "Use mock file {} for request {}, status {}".format(filename, get_request_url_suffix(flow), status))
        flow.response = http.Response.make(status, content, headers)


def get_name_of_mocked_file(url, method):
    urls = map_local.get("urls", None)
    if urls is None:
        return None

    url_with_method = method + " " + url
    filename = urls.get(url_with_method, None)
    if filename is not None:
        return filename

    filename = urls.get(url, None)
    if filename is not None:
        return filename

    filename = get_name_of_mocked_file_by_part(url_with_method)
    if filename is not None:
        return filename

    return get_name_of_mocked_file_by_part(url)


def get_name_of_mocked_file_by_part(url):
    urls = map_local.get("urls", None)
    if urls is None:
        return None

    for urlKey in urls:
        if re.search(urlKey, url):
            return urls[urlKey]

    for urlKey in urls:
        if url.startswith(urlKey):
            return urls[urlKey]

    return None


def get_request_url_suffix(flow):
    return "..." + flow.request.url[-25:]


def get_json_dumps(data, key):
    value = get_json_value(data, key, data)
    if value is None:
        return None

    try:
        return json.dumps(value)
    except JSONDecodeError:
        pass
    return None


def get_json_value(data, key, default_value):
    try:
        if key in data:
            return data[key]
    except TypeError:
        pass
    return default_value


def is_file_not_empty(path):
    return os.path.isfile(path) and os.path.exists(path) and os.path.getsize(path) > 0


def reload_config_if_updated():
    if is_file_not_empty(CONFIG_FILE):
        global config_modified_at, map_local, delay
        timestamp = os.path.getmtime(CONFIG_FILE)
        if timestamp != config_modified_at:
            config_modified_at = timestamp
            if is_file_not_empty(CONFIG_FILE):
                yaml = YAML(typ="safe").load(open(CONFIG_FILE))
                map_local = format_map_local(yaml["map_local"])
                delay = yaml["delay"]
                ctx.log.warn("Load configuration file " + CONFIG_FILE)
                return None
    else:
        ctx.log.error("Error read file " + CONFIG_FILE)
        return None


def format_map_local(map):
    if map is None:
        return None

    new_map = {}
    for key in map:
        values = map[key]
        if key == 'urls':  # Remove extra spaces between method and url.
            urls = map[key]
            new_urls = {}
            for urlKey in urls:
                split_url_key = [x for x in urlKey.split(' ') if x]
                new_urls[" ".join(split_url_key)] = urls[urlKey]
            new_map[key] = new_urls
        else:
            new_map[key] = values
    return new_map
