# How to

## Pulling image
```
docker pull archypie/archlinux-arm
```

## Building image
```
cd victorpi/docker
dockerbuild -t archypie/archlinux-arm .
```
## Running container

Please run
```
docker run -ti --privileged -v /dev:/dev -v ~/.victorpi:/root/.victorpi archypie/archlinux-arm victorpi rpi-X -s Y
```
to generate a Raspberry Pi X image of Y GB

Next fire up your RPIX container with:
```
docker run -ti -p 2222:2222 --privileged -v /dev:/dev -v ~/.victorpi:/root/.victorpi archypie/archlinux-arm victorpi rpi-X -r
```

## SSHing to the container

Type
```
ssh alarm@localhost -p 2222
```
default password for alarm (arch linux arm) user is
```
alarm
```
