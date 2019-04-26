# ssh-tunnelr

ssh-tunnelr is a bash script that offer a simple way to make a range of
ssh tunnels through multiple hosts until an endpoint.

## Usage

```bash
ssh-tunnelr.sh -u username -h host.domain.com,172.16.1.8,10.3.1.3 -f 80:82
````
This will bounce from host to host and forward local ports range up to the endpoint :
````
+----------+       +----------+       +----------+       +----------+
|    80:   |       |          |       |          |       |   :80    |
|       \  |       |          |       |          |       |  /       |
|        \ |       |:22    22:|       |:22    22:|       | /        |
|    81: --===============================================-- :81    |
|        / |       |          |       |          |       | \        |
|       /  |       |          |       |          |       |  \       |
|    82:   |       |          |       |          |       |   :82    |
+----------+       +----------+       +----------+       +----------+
 localhost        host.domain.com      172.16.1.8          10.3.1.3
````
...or more precisely :
````
+----------+       +----------+       +----------+       +----------+
|       22:|       |:22    22:|       |:22    22:|       |:22       |
|    . - - - - - - - - -  - - - - - - - -  - - - - - - - -          |
|   |    80:-------:80------80:-------:80------80:-------:80        |
|   |    81:-------:81------81:-------:81------81:-------:81        |
|   |    82:-------:82------82:-------:82------82:-------:82        |
|    ' - - - - - - - - -  - - - - - - - -  - - - - - - - -          |
|          |       |          |       |          |       |          |
+----------+       +----------+       +----------+       +----------+
 localhost        host.domain.com      172.16.1.8          10.3.1.3
````
Here is the command executed by the script :
```bash
$ ssh username@host.domain.com \
    -L 80:localhost:40000 \
    -L 81:localhost:40001 \
    -L 82:localhost:40002 \
    ssh username@172.16.1.8 \
        -L 40000:localhost:40000 \
        -L 40001:localhost:40001 \
        -L 40002:localhost:40002 \
            ssh username@10.3.1.3 \
            -L 40000:localhost:80 \
            -L 40001:localhost:81 \
            -L 40002:localhost:82
````
It is possible to specify output ports range with -f option by specifying third port number.
````
-f 7000:7002:80
````
so result is :
````
+----------+       +----------+       +----------+       +----------+
|       22:|       |:22    22:|       |:22    22:|       |:22       |
|    . - - - - - - - - -  - - - - - - - -  - - - - - - - -          |
|   |  7000:-------:7000--7000:-------:7000--7000:-------:80        |
|   |  7001:-------:7001--7001:-------:7001--7001:-------:81        |
|   |  7002:-------:7002--7002:-------:7002--7002:-------:82        |
|    ' - - - - - - - - -  - - - - - - - -  - - - - - - - -          |
|          |       |          |       |          |       |          |
+----------+       +----------+       +----------+       +----------+
````
