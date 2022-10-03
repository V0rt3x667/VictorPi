```````````````````````````````````````````````````````````
 ▄▄   ▄▄ ▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄ ▄▄▄▄▄▄   ▄▄▄▄▄▄▄ ▄▄▄ 
█  █ █  █   █       █       █       █   ▄  █ █       █   █
█  █▄█  █   █       █▄     ▄█   ▄   █  █ █ █ █    ▄  █   █
█       █   █     ▄▄█ █   █ █  █ █  █   █▄▄█▄█   █▄█ █   █
█       █   █    █    █   █ █  █▄█  █    ▄▄  █    ▄▄▄█   █
 █     ██   █    █▄▄  █   █ █       █   █  █ █   █   █   █
  █▄▄▄█ █▄▄▄█▄▄▄▄▄▄▄█ █▄▄▄█ █▄▄▄▄▄▄▄█▄▄▄█  █▄█▄▄▄█   █▄▄▄█
```````````````````````````````````````````````````````````

A set of scripts to emulate a Raspberry Pi using Arch Linux ARM, Alpine Linux, Docker and QEMU. The script can also generate Arch Linux ARM .img files that can be deployed on real hardware and/or used as virtual storage in QEMU.

This project is derived from simonpi https://github.com/M0Rf30/simonpi by M0Rf30. Re-animated and re-stiched as VictorPi by me V0rt3x667 for my own nefarious ends.

### Software Required
```shell
sudo pacman -Syyu
sudo pacman -S git docker docker-buildx
```

### Clone VictorPi
```shell
git clone --depth 1 https://github.com/V0rt3x667/victorpi
```

### Building the Docker Image
```shell
cd docker
./build.sh
```

### Creating the Arch Linux ARM Image
Generate a Raspberry Pi 2 Arch Linux ARM Image of X GB:
```shell
docker run -ti --privileged -v /dev:/dev -v ~/.victorpi:/root/.victorpi victorpi-vm victorpi.sh rpi-2 -s X
```
Generate a Raspberry Pi 3 Arch Linux ARM Image of X GB:
```shell
docker run -ti --privileged -v /dev:/dev -v ~/.victorpi:/root/.victorpi victorpi-vm victorpi.sh rpi-3 -s X
```

### Running the Docker QEMU Container
```shell
docker run -ti -p 2222:2222 --privileged -v /dev:/dev -v ~/.victorpi:/root/.victorpi victorpi-vm victorpi.sh rpi-X -r
```

### SSHing to the Docker Container
```shell
ssh alarm@localhost -p 2222
```
Default Username and Password:
```shell
alarm
```
Switch to the Root User, the Password is: root
```shell
su -
```

### View VictorPi Options
```shell
docker run -ti -p 2222:2222 --privileged -v /dev:/dev -v ~/.victorpi:/root/.victorpi victorpi-vm victorpi.sh
```
