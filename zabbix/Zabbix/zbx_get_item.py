import requests
import json

class ZabbixAPI:
    def __init__(self, url, username, password):
        self.url = url
        self.username = username
        self.password = password
        self.headers = {'Content-Type': 'application/json-rpc'}
        self.auth_token = None
        self.login()

    def _request(self, method, params=None):
        payload = {
            'jsonrpc': '2.0',
            'method': method,
            'params': params or {},
            'id': 1,
            'auth': self.auth_token if self.auth_token else None
        }
        response = requests.post(self.url, data=json.dumps(payload), headers=self.headers)
        result = response.json().get('result')
        if 'error' in response.json():
            raise Exception(response.json()['error'])
        return result

    def login(self):
        params = {
            'user': self.username,
            'password': self.password
        }
        self.auth_token = self._request('user.login', params=params)

    def get_host_id(self, host_name):
        params = {
            'output': ['hostid'],
            'filter': {'host': [host_name]}
        }
        return self._request('host.get', params=params)[0]['hostid']

    def get_hosts_by_group_id(self, group_id):
        params = {
            'output': ['host'],
            'groupids': group_id,
        }
        try:
            response = self._request('host.get', params=params)
        except Exception as e:
            print(f"Error occurred while trying to get hosts by group id {group_id}: {e}")
            return []

        host_names = [host['host'] for host in response]
        return host_names

    def get_item_id(self, host_id, item_name):
        params = {
            'output': ['itemid'],
            'hostids': host_id,
            'filter': {'name': [item_name]}
        }
        return self._request('item.get', params=params)[0]['itemid']

    def get_latest_data(self, item_id):
        history_types = ['0', '1', '2', '3', '4']
        for history_type in history_types:
            params = {
                'output': ['clock', 'value'],
                'itemids': [item_id],
                'history': history_type,
                'sortfield': 'clock',
                'sortorder': 'DESC',
                'limit': 1
            }
            history = self._request('history.get', params=params)
            if history:
                return history[0]['value']
        return None

    def get_monitoring_data(self, host_name, item_name):
        host_id = self.get_host_id(host_name)
        item_id = self.get_item_id(host_id, item_name)
        return self.get_latest_data(item_id)

if __name__ == "__main__":
    zabbix_api = ZabbixAPI('http://10.245.152.15/api_jsonrpc.php', 'sin', 'love2014520')

    group_id = '108'
    items = ['docker_running', 'firewalld_running']

    hostnames = zabbix_api.get_hosts_by_group_id(group_id)

    for host_name in hostnames:
        for item in items:
            try:
                data = {
                    'Host': host_name,
                    'Item': item,
                    'Value': zabbix_api.get_monitoring_data(host_name, item)
                }
                print(json.dumps(data))
            except Exception as e:
                pass
                # print(f"Error occurred while getting data for host {host_name} and item {item}: {e}")
