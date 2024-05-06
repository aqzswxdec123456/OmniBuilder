import requests
import json
import sys


class ZabbixAPI:
    def __init__(self, url, username, password):
        self.url = url
        self.username = username
        self.password = password
        self.headers = {'Content-Type': 'application/json-rpc'}
        self.auth_token = None

    def _request(self, method, params=None):
        payload = {
            'jsonrpc': '2.0',
            'method': method,
            'params': params or {},
            'id': 1,
            'auth': self.auth_token
        }
        response = requests.post(self.url, data=json.dumps(payload), headers=self.headers)
        result = response.json().get('result')
        if 'error' in response.json():
            raise Exception(response.json()['error'])
        return result

    def login(self):
        if self.auth_token:
            return self.auth_token

        params = {
            'user': self.username,
            'password': self.password
        }
        self.auth_token = self._request('user.login', params=params)
        return self.auth_token

    def get_host_all(self):
        return self._request('host.get', params={'output': ['name'], 'selectInterfaces': ['ip']})

    def get_host_filter(self, host_name, choose):
        if choose == "check":
            return self._request('host.get', params={'output': ['name'], 'filter': {'host': [host_name]}})[0]['name']
        elif choose == "del":
            return self._request('host.get', params={'output': ['name'], 'filter': {'host': [host_name]}})[0]['hostid']
        else:
            return "填入錯誤值"

    def create_host(self, host_name, ip_address, group, template):
        params = {
            'host': host_name,
            'name': '',
            'interfaces': [{'type': 1, 'main': 1, 'useip': 1,'ip': ip_address,'dns': '','port': '10050'}],
            'groups': [{'groupid': group}],
            'templates': [{'templateid': template}]
        }
        return self._request('host.create', params=params)

    def delete_host(self, hostname_id):
        params = [hostname_id]
        return self._request('host.delete', params=params)


if __name__ == "__main__":
    zabbix_api = ZabbixAPI('http://<ip>/zabbix/api_jsonrpc.php', '<user>', '<password>')
    auth_token = zabbix_api.login()
    if sys.argv[1] == "add":
        hostname = sys.argv[2]
        ip = sys.argv[3]
        group_id = sys.argv[4]
        template_id = sys.argv[5]
        zabbix_api.create_host(hostname, ip, group_id, template_id)
    elif sys.argv[1] == "del":
        hostname = sys.argv[2]
        host_id = zabbix_api.get_host_filter(hostname, 'del')
        zabbix_api.delete_host(host_id)
    elif sys.argv[1] == "check_all":
        check_hostname_all = zabbix_api.get_host_all()
        print(check_hostname_all)
    else:
        print("請填正確")
