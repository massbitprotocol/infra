# read nginx default config file
fin = open("default_stub", "rt")
data = fin.read()

# TODO Replace IP of workers manually
print("Updating worker IPs to nginx ...")
data = data.replace('REPLACEABLE_MASSBIT_BSC_WORKERS_IP', '\nserver 192.168.0.2; \nserver 192.168.0.1; ')
fin.close()
fin = open("default", "wt")
fin.write(data)
fin.close()