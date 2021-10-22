
# Start Docker Containers
Make sure you have `docker` otherwise you should install it.
```sh
# Build the docker image
$ docker-compose build

# Start the docker container
$ docker-compose up

# If you want to let the container be running in the background run the following command instead.
$ docker-compose up -d

$ docker exec -it master_node bash
$ bash /shared/build.sh
$ exit
```

# SSH BEST PRACTICES

## Introduction

If you want to follow this tutorial please remove all files but not folder located in `shared/`
```sh
rm -rf shared/user_ca/*
rm -rf shared/host_ca/*
rm -rf shared/master_node/*
rm -rf shared/worker_node/*
rm -rf shared/worker_node2/*
```

There are no issues with the ssh it is also really good, but this tutorial will explain how to use `ssh-keys ca` signing keys. If you are reading this tutorial I will assume that you already know something about ssh-keys and you use your public key to login into your server, if that is the case please keep reading, if not please stop there because this tutorial is not for you.

## SSH Certificates
Most people use the public key to authenticate into the server, and that is great because is not necessary to use a password. The only thing you have to do is to copy your `ssh-key.pub` in the server `~/.ssh/authorized_keys` to be able to start authentications without the need for any password. However, it is pretty annoying if you work from different machines, or you are the administrator and need to provide access to different users. You are not going to provide root access to anyone except if you authorize that. Then, now is possible to start talking about better practices and much better security.

### Generating SSH Keys

This repository has predefined some ssh-keys it is up to you to create new keys or work with the current keys that are in the folder `./shared`, but this tutorial is assuming that the `./shared` folder is empty. Then, let's start creating the most important keys that you have to keep well protected and storage and please do not distribute the private keys.

```sh
$ ssh-keygen -t rsa -C 'user_ca' -N "" -f shared/user_ca/user_ca

Generating public/private RSA key pair.
Your identification has been saved in shared/user_ca/user_ca
Your public key has been saved in shared/user_ca/user_ca.pub
The key fingerprint is:
SHA256:EN6u1om8XjTid/fyLbZScvefpsLm32TRRPxAkQpJ1Ds user_ca
The key's randomart image is:
+---[RSA 3072]----+
|      .  ooo .o+.|
|     . o  o . o..|
|      o .  . o .o|
|       o    E  .o|
|      . S    . ..|
|     o * o  . o o|
|      * = o .+ +.|
|     . + . =o.*oo|
|     .o   o.oB*=+|
+----[SHA256]-----+

```
The previous command creates the ssh-keys without a passphrase, but for much better practices and if you are worried that someone else is accessing your keys, then, is important to add the `passphrase` by removing the flag `-N` in the previous command. check the files that were generated in the folder `shared/user_ca`
```sh
$ ls -la shared/user_ca

-rw------- 1 user group 2590 Oct 22 12:29 user_ca
-rw-r--r-- 1 user group  561 Oct 22 12:29 user_ca.pub
```
These files are very important because you need the private key `user_ca` to sign certificates and you need the public key `user_ca.pub` to be located in your server where you want users to log in. Protect and never share your private key `user_ca`

Login into the master node and copy the public key `user_ca.pub` into `/etc/ssh/` and update the `/etc/ssh/sshd_config`. In this file add the `TrustedUserCAKeys` to make sure the `PubkeyAuthetication` is equal to YES and `PasswordAuthentication` is equal to NO. After these changes restart the service.

```sh
$ docker exec -it master_node bash
$ cp -rf /shared/user_ca/user_ca.pub /etc/ssh/

$ vim /etc/ssh/sshd_config
- TrustedUserCAKeys /etc/ssh/user_ca.pub
- PubkeyAuthentication yes
- PasswordAuthentication no

$ systemctl restart sshd.service
$ exit
```

### Sign CA Certificate for workers
With the previous changes is possible to login into the server if the user has a certificate signed by the private key `user_ca` let's do that. The `worker_node` does not have ssh-keys yet so let's generate them because the signing process requires the public key `worker_node.pub`

```sh
$ ssh-keygen -t rsa -C 'worker_node' -N '' -f shared/worker_node/worker_node

Generating public/private RSA key pair.
Your identification has been saved in shared/worker_node/worker_node
Your public key has been saved in shared/worker_node/worker_node.pub
The key fingerprint is:
SHA256:l5NT2M5quEBChglk9glpl5QPCeFNT6QU2OTIaIRit7I worker_node
The key's randomart image is:
+---[RSA 3072]----+
|+OO**o           |
|X*O@=      o     |
|===**.    . o    |
|.. + .     *     |
|  o . . S * o    |
| E   o   o +     |
|      . . o      |
|       . o       |
|        .        |
+----[SHA256]-----+
```

These keys are the same that get located in the `/home/.ssh/id_rsa` folder but this example is just changing the location and file name, please don't get confused. Now is possible to sign the certificate. As an administrator you know which users are available in the server `master_node` that you want to provide access to the server.

The `master_node` has a user called `ec2-user` but it is up to you if you want to create another user and test with your custom user. You can create a new user with the following command.
```sh
$ docker exec -it master_node bash
$ useradd -m -p password customusername
$ exit
```
You don't have to run the previous command because the `ec2-user` is already created when you build the container. Now let's do the job of signing the certificate.
```sh
$ ssh-keygen -s shared/user_ca/user_ca -I 'worker_node_ca' -n 'ec2-user' -V -1d:+1w shared/worker_node/worker_node.pub

Signed user key shared/worker_node/worker_node-cert.pub: id "worker_node_ca" serial 0 for ec2-user valid from 2021-10-21T13:47:10 to 2021-10-29T13:47:10
```
Now with this certificate, you will be able to log in from the `worker_node` to the `master_node`, lets test if it is possible to log in from the worker_node check the following commands.
- `-s` specifies the filename of the CA private key that should be used for signing.
- `-I worker_node` is the certificate identity for the server.
- `-n` very important parameter to specify which users are allowed to authenticate into the server.
- `-V` validity period of the certificate stands for `-1d` that the certificate started one day previous and will be valid for one week `+1w`.
- `N` Passphrase
- `C` Comment
- `f` file path



```sh
$ docker exec -it worker_node bash
$ ssh -i /shared/worker_node/worker_node ec2-user@master_node

exit
exit
```

If everything went well now you are logged into the `master_server` and congratulations you have the knowledge of the ssh best practices and now you can secure your server, you can do the same process for the `worker_node2`. The same idea can be applied to the host certificates.



