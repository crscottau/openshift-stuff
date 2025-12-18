# Harbor

[https://goharbor.io/docs/2.14.0/install-config/installation-prereqs/]

## Docker engine

```bash
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
```

## Download installer

Download the installer from: [https://github.com/goharbor/harbor/releases] and unpack

## Generate certs

Generate the CA key and certificate:

```bash
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/CN=MyPersonal Root CA" \
 -key ca.key \
 -out ca.crt
```

Generate the server key and certificate request

```bash
openssl genrsa -out harbor.key 4096
openssl req -sha512 -new \
    -subj "/CN=example.com" \
    -key harbor.key \
    -out harbor.csr
```

Create an extensions file

```bash
cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=example.com
DNS.2=harbor.example.com
DNS.3=harbor
EOF
```

Generate the certificate

```bash
openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -in harbor.csr \
    -out harbor.crt
```

Create a harbor directory and copy the cert and key

```bash
sudo mkdir -p /data/cert
sudo cp harbor.crt harbor.key /data/cert
```

Copy the certs to the docker cert directory

```bash
sudo mkdir -p /etc/docker/certs.d/
sudo cp harbor.crt harbor.key /etc/docker/certs.d/
sudo systemctl restart docker
```

## Configure the harbor yml file

## install

sudo ./preparegrep hostfs 