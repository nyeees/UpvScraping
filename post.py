#!/bin/python3
import json
import requests
s=requests.Session()
url='https://poliformat.upv.es/portal/site/!gateway-es/tool/351c5e3d-c2e5-45ba-b34b-8814e7e01e27/login_alumno'
payload = {
        'id':'c',
        'estilo':'500',
        'vista':'MSE',
        'cua':'sakai',
        'clau': 'XXXXX',
        'dni':'XXXXXXX'}
x=s.post(url=url, data=payload,)
print(x.text)
