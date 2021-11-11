Host Preparations
=================

Preparing hosts for deploying Fapro.

Git Installations
-----------------

Execute the following command to install Git:

.. code-block:: bash

    sudo dnf install git

Podman Installations
--------------------

Execute the following command to install Podman:

.. code-block:: bash

    sudo dnf install podman dnsmasq crun

Installing Podman plugin ``dnsname``
------------------------------------

.. note::

    Skip this Section if ``/usr/libexec/cni/dnsname`` file exists.

Podman plugin ``dnsname`` may not be available if ``containernetworking-plugins`` version is lower than `1.0.1`.

Clone ``dnsname`` repository and build:

.. code-block:: bash

    git clone https://github.com/containers/dnsname.git
    chcon -R -v -t container_file_t ./dnsname
    podman run -it --rm --workdir=/opt/dnsname -v ./dnsname:/opt/dnsname:rw docker.io/golang:1.17.3 make

Copy the binary files into Podman plugins directory and fix permissions:

.. code-block:: bash

    sudo cp -v ./dnsname/bin/dnsname /usr/libexec/cni/dnsname
    sudo chcon -v -u system_u /usr/libexec/cni/dnsname
    sudo chmod og+rx /usr/libexec/cni/dnsname

SELinux Utilities
-----------------

Install ``udica`` which is required for simplifying SELinux for containers:

.. code-block:: bash

    sudo dnf install udica

Configure Podman
----------------

Create ``/etc/containers/containers.conf`` if not exists:

.. code-block:: bash

    sudo cp -v /usr/share/containers/containers.conf /etc/containers/containers.conf
    sudo chmod og+r /etc/containers/containers.conf

Then, in ``/etc/containers/containers.conf``, make sure ``ulimits`` is set to at least ``65535`` and make ``memlock`` unlimited. Also make sure the ``runtime`` is set to ``crun`` instead of ``runc``:

.. code-block:: text

    [containers]

    default_ulimits = [ 
      "nofile=65535:65535",
      "memlock=-1:-1"
    ]

    [engine]

    runtime = "crun"

.. note::

    Using ``runtime = "crun"`` is recommended compared to ``runtime = "runc"`` because Podman pod cannot bind port when using ``hostNetwork: true`` in pod YAML file.

Since the ``ulimit`` config above is applied globally, it will cause a permission error when Podman is executed as rootless. To prevent this error, create an empty ``default_ulimits`` in ``~/.config/containers/containers.conf`` file:

.. code-block:: text

    [containers]

    default_ulimits = []

Configure ``sysctl``
--------------------

Create ``/etc/sysctl.d/vm-max-map-counts.conf`` with the following line:

.. code-block:: text

    vm.max_map_count=262144

To apply ``vm.max_map_count`` without reboot, execute the following command:

.. code-block:: text

    sudo sysctl -w vm.max_map_count=262144

Allow Rootless Podman to Limit Resources
----------------------------------------

Enable Unified Cgroup:

.. code-block:: bash

    sudo grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=1"
    sudo grub2-mkconfig -o /etc/grub2.cfg
    sudo grub2-mkconfig -o /etc/grub2-efi.cfg

Install the following package to provide ``/sys/fs/cgroup/user.slice/``:

.. code-block:: bash

    sudo dnf install systemd-pam

Create ``/etc/systemd/system/user@.service.d/`` directory:

.. code-block:: bash

    sudo mkdir -pv /etc/systemd/system/user@.service.d/

Create ``/etc/systemd/system/user@.service.d/delegate.conf`` file with the following lines:

.. code-block:: text

    [Service]
    Delegate=memory pids cpu io

Reboot.

Execute the following command and make sure the output is ``cpu io memory pids``:

.. code-block:: bash

    cat /sys/fs/cgroup/user.slice/user-1000.slice/user@1000.service/cgroup.controllers

.. note::

    If the output is empty, try execute ``sudo systemctl daemon-reload`` and the re-execute the command above.

To test rootless Podman, execute the following command:

.. code-block:: bash

    podman run --rm --cpus 1 docker.io/alpine echo hello

Allow non-privileged bind ports lower than 1024
-----------------------------------------------

Create ``/etc/sysctl.d/allow-unprivileged-ports-bind.conf`` with the following lines:

.. code-block:: bash

    net.ipv4.ip_unprivileged_port_start=21

To apply changes without reboot, execute the following command:

.. code-block:: bash

    sudo sysctl -w net.ipv4.ip_unprivileged_port_start=21
