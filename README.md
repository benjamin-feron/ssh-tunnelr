# ssh-tunnelr

ssh-tunnelr is a shell script that offer a simple way to establish a Secure Shell connection
through multiple hosts to an endpoint.

It permit declaration of multiple TCP port ranges to forward.

## Home page

[https://benjamin-feron.github.io/ssh-tunnelr](https://benjamin-feron.github.io/ssh-tunnelr)

## Repository

[https://github.com/benjamin-feron/ssh-tunnelr](https://github.com/benjamin-feron/ssh-tunnelr)

## Installation
```bash
$ git clone https://github.com/benjamin-feron/ssh-tunnelr.git
$ cd ssh-tunnelr
$ ln -s $PWD/ssh-tunnelr.sh /usr/bin/ssh-tunnelr
````

## Usage

```bash
$ ssh-tunnelr -t host.domain.com,172.16.1.55,10.3.1.3 80:82
````
This will bounce from host to host and forward local ports range up to the endpoint :
````
+----------+       +----------+       +----------+       +----------+
|   :80    |       |          |       |          |       |    :80   |
|       \  |       |          |       |          |       |  /       |
|        \ |       |:22       |       |:22       |       | /        |
|   :81 ---===============================================--- :81   |
|        / |       |          |       |          |       | \        |
|       /  |       |          |       |          |       |  \       |
|   :82    |       |          |       |          |       |    :82   |
+----------+       +----------+       +----------+       +----------+
 localhost        host.domain.com      172.16.1.55         10.3.1.3
````
...or more precisely :
````
+----------+       +----------+       +----------+       +----------+
|          |       |:22       |       |:22       |       |:22       |
|    . - - - - - - - - - - - - - - - - - - - - - - - - - -          |
|   |   :80--------:80----------------:80----------------:80        |
|   |   :81--------:81----------------:81----------------:81        |
|   |   :82--------:82----------------:82----------------:82        |
|    ` - - - - - - - - - - - - - - - - - - - - - - - - - -          |
|          |       |          |       |          |       |          |
+----------+       +----------+       +----------+       +----------+
 localhost        host.domain.com      172.16.1.55         10.3.1.3
````
Here is the command executed by the script :
```bash
ssh -t host.domain.com \
  -L 80:localhost:80 \
  -L 81:localhost:81 \
  -L 82:localhost:82 \
  ssh -t 172.16.1.55 \
    -L 80:localhost:80 \
    -L 81:localhost:81 \
    -L 82:localhost:82 \
    ssh -t 10.3.1.3 \
      -L 80:localhost:80 \
      -L 81:localhost:81 \
      -L 82:localhost:82
````
-t options is to force pseudo-terminal allocation. It is often required for the different shell to open well.

### Declaration of ports to forward

#### Port range forwarding
```bash
$ ssh-tunnelr -t host1,host2,host3 7000:7002
````
so result is :
````
+----------+       +----------+       +----------+       +----------+
|          |       |:22       |       |:22       |       |:22       |
|    . - - - - - - - - - - - - - - - - - - - - - - - - - -          |
|   | :7000--------:7000--------------:7000--------------:7000      |
|   | :7001--------:7001--------------:7001--------------:7001      |
|   | :7002--------:7002--------------:7002--------------:7002      |
|    ` - - - - - - - - - - - - - - - - - - - - - - - - - -          |
|          |       |          |       |          |       |          |
+----------+       +----------+       +----------+       +----------+
 localhost             host1              host2              host3
````
#### Port range forwarding with destination ports specified
```bash
$ ssh-tunnelr -t host1,host2,host3 7000:7002:80
````
look at ports on the endpoint :
````
+----------+       +----------+       +----------+       +----------+
|          |       |:22       |       |:22       |       |:22       |
|    . - - - - - - - - - - - - - - - - - - - - - - - - - -          |
|   | :7000--------:7000--------------:7000--------------:80        |
|   | :7001--------:7001--------------:7001--------------:81        |
|   | :7002--------:7002--------------:7002--------------:82        |
|    ` - - - - - - - - - - - - - - - - - - - - - - - - - -          |
|          |       |          |       |          |       |          |
+----------+       +----------+       +----------+       +----------+
 localhost             host1              host2              host3
````
#### Single port forwarding

```bash
$ ssh-tunnelr -t host1,host2,host3 18000
````
````
+----------+       +----------+       +----------+       +----------+
|          |       |:22       |       |:22       |       |:22       |
|    . - - - - - - - - - - - - - - - - - - - - - - - - - -          |
|   |      :       :          :       :          :       :          |
|   |:18000--------:18000-------------:18000-------------:18000     |
|   |      :       :          :       :          :       :          |
|    ` - - - - - - - - - - - - - - - - - - - - - - - - - -          |
|          |       |          |       |          |       |          |
+----------+       +----------+       +----------+       +----------+
 localhost             host1              host2              host3
````
#### Single port forwarding with destination port specified

```bash
$ ssh-tunnelr -t host1,host2,host3 18000::3306
````
...that is equivalent to :
```bash
$ ssh-tunnelr -t host1,host2,host3 18000:18000:3306
````
````
+----------+       +----------+       +----------+       +----------+
|          |       |:22       |       |:22       |       |:22       |
|    . - - - - - - - - - - - - - - - - - - - - - - - - - -          |
|   |      :       :          :       :          :       :          |
|   |:18000--------:18000-------------:18000-------------:3306      |
|   |      :       :          :       :          :       :          |
|    ` - - - - - - - - - - - - - - - - - - - - - - - - - -          |
|          |       |          |       |          |       |          |
+----------+       +----------+       +----------+       +----------+
 localhost             host1              host2              host3
````
#### Combine multiple types of forwarding

You can combine several types of declarations :
```bash
$ ssh-tunnelr -t host1,host2,host3 110:111 7000:7002:80 3306
````
````
+----------+       +----------+       +----------+       +----------+
|          |       |:22       |       |:22       |       |:22       |
|    . - - - - - - - - - - - - - - - - - - - - - - - - - -          |
|   |  :110--------:110---------------:110---------------:110       |
|   |  :111--------:111---------------:111---------------:111       |
|   | :7000--------:7000--------------:7000--------------:80        |
|   | :7001--------:7001--------------:7001--------------:81        |
|   | :7002--------:7002--------------:7002--------------:82        |
|   | :3306--------:3306--------------:3306--------------:3306      |
|    ` - - - - - - - - - - - - - - - - - - - - - - - - - -          |
|          |       |          |       |          |       |          |
+----------+       +----------+       +----------+       +----------+
 localhost             host1              host2              host3
````

#### Specify username and/or ssh server port number on each hosts

```bash
$ ssh-tunnelr -t host1:2222,foo@host2,bar@host3:6822 3306
````
```bash
ssh -t -p 2222 host1 \
  -L 3306:localhost:3306 \
  ssh -t foo@host2 \
    -L 3306:localhost:3306 \
    ssh -t -p 6822 bar@host3 \
      -L 3306:localhost:3306
````
````
+----------+       +----------+       +----------+       +----------+
|          |       |:2222     |       |:22       |       |:6822     |
|    . - - - - - - - - - - - - - - - - - - - - - - - - - -          |
|   |      :       :          :       :          :       :          |
|   | :3306--------:3306--------------:3306--------------:3306      |
|   |      :       :          :       :          :       :          |
|    ` - - - - - - - - - - - - - - - - - - - - - - - - - -          |
|          |       |          |       |          |       |          |
+----------+       +----------+       +----------+       +----------+
 localhost             host1              host2              host3
                                     (username: foo)    (username: bar)
````
You also can specify password like on ssh command : user:password@host but it's not recommended since commands are generally stored in history and could potentially be acceded by another user.

### Connect to the endpoint without forwarding ports

Of course it's possible to simply connect to endpoint without specify any port to forward :
```bash
$ ssh-tunnelr -t host1:2222,host2,host3:6822
````
```bash
ssh -t -p 2222 host1 \
  ssh host2 \
    ssh -t -p 6822 host3
````
````
+----------+       +----------+       +----------+       +----------+
|          |       |          |       |          |       |          |
|          |       |          |       |          |       |          |
|          |       |          |       |          |       |          |
|         ---------:2222--------------:22----------------:6822      |
|          |       |          |       |          |       |          |
|          |       |          |       |          |       |          |
|          |       |          |       |          |       |          |
+----------+       +----------+       +----------+       +----------+
 localhost             host1              host2              host3
````
### SSH natives options

You can pass ssh native options like -X or -t.
```bash
$ ssh-tunnelr -X -t host1,host2,host3 70:71
````
...ssh command becomes :
```bash
ssh -X -t host1 \
  -L 70:localhost:70 \
  -L 71:localhost:71 \
  ssh -X -t host2 \
    -L 70:localhost:70 \
    -L 71:localhost:71 \
    ssh -X -t host3 \
      -L 70:localhost:70 \
      -L 71:localhost:71
````

### All options

```
Usage: ssh-tunnelr [OPTIONS|SSH OPTIONS] HOST[S] [RANGE] [RANGE...]

  Hosts:                 Hosts separate by ',' e.g. host.domain.com,172.16.1.8,user@10.1.8.1:2222
                         An host is defined by [user@]host[:ssh_port] where user and ssh_port are optional
  Range(s)               Ports to forward to endpoint. This can be a single port e.g. 80 or a range e.g. 80:82.
                         You also can specify output port range with a third port number e.g. 7000:7002:80.
                         So port 7000 will be forwarded on port 80 of the endpoint, 7001 on 81 and 7002 on 82.
                         For single port combined with output port scpecified, you have to write 7000:7000:80.
                         Several ranges are allowed and must be separated by spaces  e.g 10000:10008 7000:7002:80 3306.
  Options:
    -d, --dry            Dry mode, for test. With this option, ssh command is not launched, it's only shown.
    -h, --hide-tunnels   Don't show tunnels in command output. Especially useful when you need large range of ports
                         and your screen is too small.
    -q, --quiet          Quiet mode. Display no output.
    --help               Show help
  
  SSH Options:           These options are passed to each ssh command on each host.
    -t                   Force pseudo-terminal allocation.
    -X                   Enables X11 forwarding.
  
  Example:               ssh-tunnelr foo@host.domain.com,172.16.1.11,bar@10.5.1.10:2222 7000:7008
````
