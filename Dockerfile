FROM centos:7
ENV container docker
VOLUME [ "/sys/fs/cgroup" ]

ADD . /root/compass-cobbler

# pkgs and services...
RUN yum -y update && \
    yum -y install epel-release && \
    yum -y install which wget dhcp bind pykickstart file initscripts net-tools tcpdump xinetd vim avahi avahi-tools ntp && \
    wget ftp://fr2.rpmfind.net/linux/fedora-secondary/updates/22/aarch64/c/cobbler-2.6.10-1.fc22.noarch.rpm && \
    wget ftp://fr2.rpmfind.net/linux/fedora-secondary/updates/22/aarch64/c/cobbler-web-2.6.10-1.fc22.noarch.rpm && \
    wget http://linux.enea.com/mos-repos/centos/mos8.0-centos7-fuel/armband/x86_64/Packages/cobbler-grub-aarch64-2.02~beta2-1.el7.36~mos1.noarch.rpm && \
    yum -y localinstall cobbler-2.6.10-1.fc22.noarch.rpm cobbler-web-2.6.10-1.fc22.noarch.rpm cobbler-grub-aarch64-2.02~beta2-1.el7.36~mos1.noarch.rpm && \
    rm -f cobbler-2.6.10-1.fc22.noarch.rpm cobbler-web-2.6.10-1.fc22.noarch.rpm cobbler-grub-aarch64-2.02~beta2-1.el7.36~mos1.noarch.rpm && \
    systemctl enable cobblerd && \
    systemctl enable httpd && \
    systemctl enable dhcpd && \
    systemctl enable xinetd

# some tweaks on services
RUN sed -i -e 's/\(^.*disable.*=\) yes/\1 no/' /etc/xinetd.d/tftp && \
    touch /etc/xinetd.d/rsync && \
    mkdir -p /var/www/cblr_ks && \
    cp -rf /root/compass-cobbler/distro_signatures.json /var/lib/cobbler/distro_signatures.json && \
    cp -rf /root/compass-cobbler/start.sh /usr/local/bin/start.sh && \
    mv /etc/httpd/conf.d/cobbler_web.conf /etc/httpd/conf.d/cobbler_web.conf.bk && \
    cp -rf /root/compass-cobbler/cobbler_web.conf /etc/httpd/conf.d/cobbler_web.conf && \
    mv /etc/httpd/conf.d/cobbler.conf /etc/httpd/conf.d/cobbler.conf.bk && \
    cp -rf /root/compass-cobbler/cobbler.conf /etc/httpd/conf.d/cobbler.conf && \
    mkdir -p /var/www/pip-openstack && \
    cp -rf /root/compass-cobbler/pxeprofile_arm.template /etc/cobbler/pxe/pxeprofile_arm.template && \
    cp -rf /root/compass-cobbler/pxeprofile_arm.template /etc/cobbler/pxe/pxesystem_arm.template && \
    cp -rf /root/compass-cobbler/pxeprofile_arm.template /etc/cobbler/pxe/grubsystem.template  && \
    cp -rf /root/compass-cobbler/pxeprofile_arm.template /etc/cobbler/pxe/grubprofile.template  && \
    touch /var/lib/cobbler/loaders/{pxelinux.0,menu.c32} && \
    sed -i 's/"\/pxelinux\.0"/"grub\/grub-aarch64\.efi"/' /usr/lib/python2.7/site-packages/cobbler/modules/manage_isc.py

VOLUME ["/var/lib/cobbler", "/var/www/cobbler", "/etc/cobbler", "/mnt", "/var/www/cobbler/repo_mirror", "/var/www/pip"]
EXPOSE 67
EXPOSE 69
EXPOSE 80
EXPOSE 443
EXPOSE 25151
CMD ["/sbin/init", "/usr/local/bin/start.sh"]
