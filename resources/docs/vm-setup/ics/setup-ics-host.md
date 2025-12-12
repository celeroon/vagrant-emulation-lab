# Setup host for ICS lab

Go to your Debian host KVM and run commands below:

```bash
sudo tc qdisc add dev tap-ics-src clsact
```

```bash
sudo tc filter add dev tap-ics-src ingress matchall \
       action mirred egress mirror dev tap-ics-dst
```

```bash
sudo tc filter add dev tap-ics-src egress  matchall \
       action mirred egress mirror dev tap-ics-dst
```

**Cyber Vision tap interface** 

```bash
sudo tc filter add dev tap-ics-src ingress matchall \
       action mirred egress mirror dev tap-ics-dst-cv
```

```bash
sudo tc filter add dev tap-ics-src egress  matchall \
       action mirred egress mirror dev tap-ics-dst-cv
```
