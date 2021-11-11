Development Deployment
======================

Unfortunately, `fofapro/fapro v0.43`_ is not open source. This Chapter shall demonstrate how to deploy fapro in a restricted environment for development purpose.

.. _fofapro/fapro v0.43: https://github.com/fofapro/fapro/tree/v0.43

Build our Fapro image
---------------------

From the project root directory, ``cd`` into ``deployment/development/fapro/`` and then execute the following command:

.. code-block:: bash

    cd deployment/development/fapro/
    podman build -t extra2000/fapro .

Create Podman Network (the ``fapronet``) with no Internet access
----------------------------------------------------------------

Create ``~/.config/cni/net.d/fapronet.conflist`` file:

.. code-block:: yaml

    {
      "cniVersion": "0.4.0",
      "name": "fapronet",
      "plugins": [
        {
          "type": "bridge",
          "bridge": "cni-podman1",
          "isGateway": true,
          "ipMasq": false,
          "hairpinMode": true,
          "ipam": {
            "type": "host-local",
            "routes": [{ "dst": "0.0.0.0/0" }],
            "ranges": [
              [
                {
                  "subnet": "192.168.125.0/24",
                  "gateway": "192.168.125.1"
                }
              ]
            ]
          }
        },
        {
          "type": "portmap",
          "capabilities": {
            "portMappings": true
          }
        },
        {
          "type": "firewall",
          "backend": ""
        },
        {
          "type": "tuning"
        },
        {
          "type": "dnsname",
          "domainName": "fapronet"
        }
      ]
    }

Notice that the ``"ipMasq": false,`` will ensure the ``fapronet`` will not have any Internet access.

.. note::

    If ``~/.config/cni/net.d/`` does not exists, create the directory using ``sudo mkdir -pv ~/.config/cni/net.d/``.

.. warning::

    Rename ``cni-podman1`` to ``cni-podman2`` and etc if the name is already used by other Podman deployments. Also make sure to change IP address for ``subnet`` and ``gateway`` if they are already exists in your existing deployments.

Make sure the following command failed:

.. code-block:: bash

    podman run -it --rm --network=fapronet docker.io/curlimages/curl:latest https://google.com

Deploy Fapro
------------

From the project root directory, ``cd`` into ``deployment/development/fapro/`` and then execute the following command:

.. code-block:: bash

    cd deployment/development/fapro/

Create config files:

.. code-block:: bash

    cp -v configmaps/fofapro-fapro.yaml{.example,}
    cp -v configs/config.json{.example,}

Create pod file:

.. code-block:: bash

    cp -v fofapro-fapro-pod.yaml{.example,}

For SELinux platform, label the following files to allow to be mounted into container:

.. code-block:: bash

    chcon -R -v -t container_file_t ./configs

Load SELinux security policy:

.. code-block:: bash

    sudo semodule -i selinux/fofapro_fapro.cil /usr/share/udica/templates/{base_container.cil,net_container.cil}

Verify that the SELinux module exists:

.. code-block:: bash

    sudo semodule --list | grep -e "fofapro_fapro"

Deploy fapro:

.. code-block:: bash

    podman play kube --network fapronet --configmap configmaps/fofapro-fapro.yaml --seccomp-profile-root ./seccomp fofapro-fapro-pod.yaml

Testing
-------

Test MySQL:

.. code-block:: bash

    podman run -it --rm --network=fapronet docker.io/library/mysql:latest mysql -utest -ptest --host fofapro-fapro-pod.fapronet --port 3306

Test SSH:

.. code-block:: bash

    podman run -it --rm --network=fapronet docker.io/linuxserver/openssh-server:latest ssh -p 22 root@fofapro-fapro-pod.fapronet
