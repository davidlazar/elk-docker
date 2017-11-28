# elk-docker

The goal is to make it easy to deploy the ELK stack with SSL and LetsEncrypt.
The host should expose ports 80 and 443 for Kibana, and 5044 for Logstash.

```
$ ELK_HOST=elk.example.com KIBANA_PW=secret123 ./setup.sh
$ sudo docker-compose up
```

If it worked, then Kibana will be accessible at https://elk.example.com with
username `kbadmin` and password `secret123`. 

Each Beat will need a client certificate to authenticate to Logstash.
You can generate the client private key and certificate on the ELK host:

```
$ ./EasyRSA-3.0.3/easyrsa --pki-dir=pki build-client-full metricbeat1 nopass
```

Then copy the keys to the client:

```
$ scp pki/ca.crt pki/issued/metricbeat1.crt pki/private/metricbeat1.key client.example.com:/etc/metricbeat/keys
```

Alternatively, you can generate the private key on the client using
`easyrsa gen-req` and sign the certificate request on the ELK host
using `easyrsa sign-req`.

Next, configure metricbeat to use the keys by editing `metricbeat.yml`:

```
#----------------------------- Logstash output --------------------------------
output.logstash:
  # The Logstash hosts
  hosts: ["elk.example.com:5044"]

  # List of root certificates for HTTPS server verifications
  ssl.certificate_authorities: ["/etc/metricbeat/keys/ca.crt"]

  # Certificate for SSL client authentication
  ssl.certificate: "/etc/metricbeat/keys/metricbeat1.crt"

  # Client Certificate Key
  ssl.key: "/etc/metricbeat/keys/metricbeat1.key"
```

Test that metricbeat is working on the client:

```
$ sudo metricbeat -c metricbeat.yml -e -v
```
