# Object storage

## Linux profile

`sudo tuned-adm profile throughput-performance`

## MinIO

<https://min.io/docs/minio/linux/operations/install-deploy-manage/deploy-minio-single-node-single-drive.html#minio-snsd>

Install:

```bash
curl https://dl.min.io/server/minio/release/linux-amd64/minio-20250907161309.0.0-1.x86_64.rpm -o minio.rpm
sudo dnf install -y minio.rpm
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
$ mkdir -p /etc/default
$ cat <<__EOF > /etc/default/minio  
MINIO_VOLUMES="/var/object-data/"
MINIO_OPTS="-C /etc/minio --address :9000 --console-address :9001"
MINIO_ROOT_USER="minio"
MINIO_ROOT_PASSWORD="2wsx#EDC"
__EOF
cat /etc/default/minio
exit
```

Enable and start it:

`sudo systemctl enable --now minio`

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
