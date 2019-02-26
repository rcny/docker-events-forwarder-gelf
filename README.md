docker-events-forwarder-gelf
==========

This is small container-based utility which performs as an Docker events listener and sender to remote GELF inputs. It grabs arriving events as-is via the local UNIX socket and forwards them to remote endpoints.

### Configuration

All configuration is performed via environment variables:

```
HOST=<address of the gelf input>
PORT=<port of the gelf input>
PROTO=<message transport. can be tcp or udp>
CHUNK_SIZE=<udp chunk sizing type. can be lan or wan>
```

You also have to set `HOST_HOSTNAME` variable or mount host's `/etc/hostname` as `/etc/host-hostname` inside the application container to get correct `source` field for your GELF message. Without that, you will be left with truncated container ID as message's `source`.

Currently forwarder simply connects to `unix:///var/run/docker.sock` and has no ability for Docker host configuration and authentication.

### Example usage

Run directly with Docker CLI:

`docker run -d -e HOST=foo.bar -e PORT=1337 -e PROTO=udp -e CHUNK_SIZE=lan -v /etc/hostname:/etc/host-hostname:ro -v /var/run/docker.sock:/var/run/docker.sock:ro --restart unless-stopped rcny/docker-events-forwarder-gelf`
