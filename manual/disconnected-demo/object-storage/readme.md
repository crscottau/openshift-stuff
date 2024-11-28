# Object storage

https://min.io/docs/minio/linux/operations/install-deploy-manage/deploy-minio-single-node-single-drive.html#minio-snsd

Install:

```
$ curl https://dl.min.io/server/minio/release/linux-amd64/archive/minio-20241107005220.0.0-1.x86_64.rpm -o minio.rpm
$ sudo dnf install minio.rpm
```
Create the user

`$ sudo useradd minio-user`

Create the data directory

```
$ sudo mkdir /data
$ sudo chown minio-user:minio-user /data
```

Create the environment variable file:

```
$ cat /etc/default/minio
MINIO_VOLUMES="/data/"
MINIO_OPTS="-C /etc/minio --address 192.168.23.11:9000"
MINIO_ACCESS_KEY="minio"
MINIO_SECRET_KEY="2wsx#EDC"
```

Start it:

`$ sudo systemctl start minio`