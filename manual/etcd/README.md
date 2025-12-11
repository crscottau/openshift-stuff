# Add new etcd member

```bash
$ oc -n openshift-etcd get pods -l k8s-app=etcd                                                                                                                      
NAME                        READY   STATUS    RESTARTS   AGE                                                                                                                                   
etcd-qqv78-frhqq-master-1   4/4     Running   0          13m                                                                                                                                   
etcd-qqv78-frhqq-master-2   4/4     Running   0          7m44s                                                                                                                                 
```

```bash
$ oc -n openshift-etcd rsh etcd-qqv78-frhqq-master-1                                                                                                                 
sh-5.1# etcdctl member list -w table                                                                                                                                                           
+------------------+---------+----------------------+-----------------------------+-----------------------------+------------+
|        ID        | STATUS  |         NAME         |         PEER ADDRS          |        CLIENT ADDRS         | IS LEARNER |
+------------------+---------+----------------------+-----------------------------+-----------------------------+------------+
| 78534555711cfa70 | started | qqv78-frhqq-master-2 |  https://192.168.16.75:2380 |  https://192.168.16.75:2379 |      false |
| ad50f7020ed6e435 | started | qqv78-frhqq-master-1 | https://192.168.16.139:2380 | https://192.168.16.139:2379 |      false |
+------------------+---------+----------------------+-----------------------------+-----------------------------+------------+
```

`sh-5.1# etcdctl member remove 6fc1e7c9db35841d`

```bash
sh-5.1# etcdctl member list -w table                                                            
+------------------+---------+----------------------+-----------------------------+-----------------------------+------------+
|        ID        | STATUS  |         NAME         |         PEER ADDRS          |        CLIENT ADDRS         | IS LEARNER |
+------------------+---------+----------------------+-----------------------------+-----------------------------+------------+
| 78534555711cfa70 | started | qqv78-frhqq-master-2 |  https://192.168.16.75:2380 |  https://192.168.16.75:2379 |      false |
| ad50f7020ed6e435 | started | qqv78-frhqq-master-1 | https://192.168.16.139:2380 | https://192.168.16.139:2379 |      false |
+------------------+---------+----------------------+-----------------------------+-----------------------------+------------+
sh-5.1# exit
```

```bash
$ oc patch etcd/cluster --type=merge -p '{"spec": {"unsupportedConfigOverrides": {"useUnsupportedUnsafeNonHANonProductionUnstableEtcd": true}}}'
etcd.operator.openshift.io/cluster patched
```

Apply the saved/edited machine YAML

```bash
$ oc apply -f qqv78-frhqq-master-0.yaml 
machine.machine.openshift.io/qqv78-frhqq-master-0 configured
```

```bash
$ oc -n openshift-etcd get pods -l k8s-app=etcd
NAME                        READY   STATUS    RESTARTS   AGE
etcd-qqv78-frhqq-master-0   4/4     Running   0          6m32s
etcd-qqv78-frhqq-master-1   4/4     Running   0          10m
etcd-qqv78-frhqq-master-2   4/4     Running   0          8m33s
```

```bash
$ oc -n openshift-etcd rsh etcd-qqv78-frhqq-master-1 etcdctl member list -w table
+------------------+---------+----------------------+-----------------------------+-----------------------------+------------+
|        ID        | STATUS  |         NAME         |         PEER ADDRS          |        CLIENT ADDRS         | IS LEARNER |
+------------------+---------+----------------------+-----------------------------+-----------------------------+------------+
| 78534555711cfa70 | started | qqv78-frhqq-master-2 |  https://192.168.16.75:2380 |  https://192.168.16.75:2379 |      false |
| 8560df1db4986ba9 | started | qqv78-frhqq-master-0 | https://192.168.16.142:2380 | https://192.168.16.142:2379 |      false |
| ad50f7020ed6e435 | started | qqv78-frhqq-master-1 | https://192.168.16.139:2380 | https://192.168.16.139:2379 |      false |
+------------------+---------+----------------------+-----------------------------+-----------------------------+------------+
```

```bash
$ oc -n openshift-etcd rsh etcd-qqv78-frhqq-master-1 etcdctl endpoint health
https://192.168.16.139:2379 is healthy: successfully committed proposal: took = 8.383751ms
https://192.168.16.142:2379 is healthy: successfully committed proposal: took = 10.125661ms
https://192.168.16.75:2379 is healthy: successfully committed proposal: took = 10.583718ms
```
