# Object storage

<https://min.io/docs/minio/linux/operations/install-deploy-manage/deploy-minio-single-node-single-drive.html#minio-snsd>

Install:

```bash
curl https://dl.min.io/server/minio/release/linux-amd64/archive/minio-20241107005220.0.0-1.x86_64.rpm -o minio.rpm
sudo dnf install minio.rpm
```

Create the user

`$ sudo useradd minio-user`

Create the data directory

```bash
sudo mkdir /var/object-data
sudo chown minio-user:minio-user /var/object-data
```

Create the environment variable file:

```bash
$ cat /etc/default/minio
MINIO_VOLUMES="/var/object-data/"
MINIO_OPTS="-C /etc/minio --address 192.168.123.20:9000"
MINIO_ACCESS_KEY="minio"
MINIO_SECRET_KEY="2wsx#EDC"
```

Start it:

`sudo systemctl start minio`

Open firewall ports:

```bash
sudo firewall-cmd --add-port 9000/tcp
sudo firewall-cmd --add-port 9000/tcp --permanent
sudo firewall-cmd --add-port 45161tcp
sudo firewall-cmd --add-port 45161/tcp --permanent
```

Note: port 9000 is static, the other port, for the admin UI, changes.
