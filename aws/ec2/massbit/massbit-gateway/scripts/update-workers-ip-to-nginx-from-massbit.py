import requests
import json

# Helpers
def array_of_bytes_to_string(arr):
    return "".join(map(chr, arr))

# Read nginx default config file
fin = open("default_stub", "rt")
data = fin.read()

# Call to Massbit to get un-parsed list of IPs
url = "https://dev-api.massbit.io"
payload = "{\n     \"jsonrpc\":\"2.0\",\n      \"id\":1,\n      \"method\":\"massbit_getWorkers\",\n      \"params\": []\n    }"
headers = {
  'Content-Type': 'application/json;charset=utf-8'
}
response = requests.request("POST", url, headers=headers, data=payload)


# Just printing Blacklist IPs
blacklist = []
bl = []
for x in json.loads(response.text)["result"]:
    if bool(x[3]) == False:
        blacklist.append(array_of_bytes_to_string(x[1]))
for x in blacklist:
    bl.append('\n  ' + x + ';')
fmtBlackList = "".join(bl)
print("IPs that are in blacklist:" , fmtBlackList)


# Parsing bytes of IPs to IP
mylist = []
for x in json.loads(response.text)["result"]:
    # Remove IPs that are blacklist
    if bool(x[3] == True): 
        mylist.append(array_of_bytes_to_string(x[1]))

# Quick way to get unique IPs
myset = set(mylist)
mylist = list(myset)

# Modified IPs (add prefix so that nginx file can understand these IPs)
ips = []
for x in mylist:
    ips.append('\n  server ' + x + ';')
modified_ips = "".join(ips)
print("Worker IPs that will be added to nginx:" + modified_ips)

# Update Worker IPs to nginx
data = data.replace('REPLACEABLE_MASSBIT_BSC_WORKERS_IP', modified_ips)
fin.close()
fin = open("default", "wt")
fin.write(data)
fin.close()
