# ssh-tunnelr

ssh-tunnelr is a bash script that offer a simple way to make a range of
ssh tunnels through multiple hosts until an end point.

## Usage

```bash
ssh-tunnelr.sh -u username -h host.domain.com,172.16.1.8,10.3.1.3 -p 80:82
````
This will bounce from host to host and forward local ports range up to the end point :
````
+---------------+       +---------------+       +---------------+       +---------------+
|        80:    |       |               |       |               |       |    :80        |
|           \   |       |               |       |               |       |   /           |
|            \  |       |               |       |               |       |  /            |
|        81: ---+=======================================================+--- :81        |
|             / |       |               |       |               |       |  \            |
|            /  |       |               |       |               |       |   \           |
|        82:    |       |               |       |               |       |    :82        |
+---------------+       +---------------+       +---------------+       +---------------+
    localhost            host.domain.com           172.16.1.8               10.3.1.3
````
...or more precisely :
````
+---------------+       +---------------+       +---------------+       +---------------+
|            22:|       |:22         22:|       |:22         22:|       |:22            |
|               - - - - - - - - - - - - - - - - - - - - - - - - - - - - -               |
|        80: ----------------:40000:-----------------:40000:---------------- :80        |
|        81: ----------------:40001:-----------------:40001:---------------- :81        |
|        82: ----------------:40002:-----------------:40002:---------------- :82        |
|               - - - - - - - - - - - - - - - - - - - - - - - - - - - - -               |
|               |       |               |       |               |       |               |
+---------------+       +---------------+       +---------------+       +---------------+
    localhost            host.domain.com           172.16.1.8               10.3.1.3
````
with option -d you can specify the first internal range port number (default is 40000).

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
