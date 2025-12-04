# Object storage

## Linux profile

`sudo tuned-adm profile throughput-performance`

## MinIO

<https://min.io/docs/minio/linux/operations/install-deploy-manage/deploy-minio-single-node-single-drive.html#minio-snsd>

Install:

```bash
curl --progress-bar -L dl.min.io/aistor/minio/release/linux-amd64/minio.rpm -o minio.rpm
sudo dnf install minio.rpm
```

Create the user

`sudo useradd minio-user`

Create the data directory

```bash
sudo mkdir /var/object-data
sudo chown minio-user:minio-user /var/object-data
```

Create the environment variable file:

```bash
$ sudo -i
$ cat > /etc/default/minio <<__EOF 
MINIO_VOLUMES="/var/object-data/"
MINIO_OPTS="-C /etc/minio --address :9000 --console-address :9001"
MINIO_ROOT_USER="minio"
MINIO_ROOT_PASSWORD="2wsx#EDC"
__EOF
cat /etc/default/mini
exit
```

Start it:

`sudo systemctl start minio`

Open firewall ports:

```bash
sudo firewall-cmd --add-port 9000/tcp --permanent
sudo firewall-cmd --add-port 9001/tcp --permanent
sudo firewall-cmd --reload
```

Access the console by hitting [http://ip:9001.]

## S3 CLI

```bash
sudo dnf install s3cmd # on Fedora
s3cmd --access_key=<key>> --secret_key=<secret> --host=<ip>:9000 --host-bucket="%(bucket)" --no-ssl ls`
```
