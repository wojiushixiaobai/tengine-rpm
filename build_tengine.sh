#!/usr/bin/env bash
#

tengine_version=tengine-2.3.2
BASE_DIR=$(cd "$(dirname "$0")";pwd)
PROJECT_DIR=${BASE_DIR}

cd ~

which wget >/dev/null 2>&1
if [ $? -ne 0 ];then
    yum install -y wget
fi
if [ ! "$(rpm -qa | grep epel-release)" ]; then
    yum install -y epel-release
fi
if grep -q 'mirrors.aliyun.com' /etc/yum.repos.d/CentOS-Base.repo; then
    true
else
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
    wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
fi

if [ ! "$(rpm -qa | grep gcc-c++)" ]; then
    yum install -y gcc-c++ pcre-devel openssl-devel
fi

if [ ! -d "$tengine_version" ]; then
    wget http://tengine.taobao.org/download/${tengine_version}.tar.gz
    tar -xf ${tengine_version}.tar.gz
    wget https://github.com/openresty/headers-more-nginx-module/archive/v0.33.tar.gz
    tar -xf v0.33.tar.gz -C ${tengine_version}/modules
    rm -rf ${tengine_version}.tar.gz v0.33.tar.gz
fi

cd ${tengine_version}

./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib64/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-compat --with-file-aio --with-threads --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic -fPIC' --with-ld-opt='-Wl,-z,relro -Wl,-z,now -pie' --add-module=modules/ngx_http_upstream_check_module --add-module=modules/headers-more-nginx-module-0.33 --add-module=modules/ngx_http_upstream_session_sticky_module

make -j$(getconf _NPROCESSORS_ONLN)
cd objs

if [ ! -f nginx.8.gz ]; then
    gzip nginx.8
fi

if [ ! "$(rpm -qa | grep rpmrebuild)" ]; then
    yum install -y rpm-build rpmrebuild rpm cpio
fi

if [ ! -d "~/rpmbuild" ]; then
    mkdir -p ~/rpmbuild/BUILDROOT/${tengine_version}-1.el7.ngx.x86_64 ~/rpmbuild/SPECS
fi

cd ~/rpmbuild/BUILDROOT/${tengine_version}-1.el7.ngx.x86_64
wget http://nginx.org/packages/centos/7/x86_64/RPMS/nginx-1.16.1-1.el7.ngx.x86_64.rpm
rpm2cpio nginx-1.16.1-1.el7.ngx.x86_64.rpm | cpio -div
rm -rf nginx-1.16.1-1.el7.ngx.x86_64.rpm

rm -rf ~/rpmbuild/BUILDROOT/${tengine_version}-1.el7.ngx.x86_64/usr/sbin/nginx
cp ~/${tengine_version}/objs/nginx ~/rpmbuild/BUILDROOT/${tengine_version}-1.el7.ngx.x86_64/usr/sbin/

rm -rf ~/rpmbuild/BUILDROOT/${tengine_version}-1.el7.ngx.x86_64/etc/nginx/fastcgi.conf
cp ~/${tengine_version}/conf/fastcgi.conf ~/rpmbuild/BUILDROOT/${tengine_version}-1.el7.ngx.x86_64/etc/nginx/

rm -rf ~/rpmbuild/BUILDROOT/${tengine_version}-1.el7.ngx.x86_64/usr/share/man/man8/nginx.8.gz
mv ~/${tengine_version}/objs/nginx.8.gz ~/rpmbuild/BUILDROOT/${tengine_version}-1.el7.ngx.x86_64/usr/share/man/man8/

rm -rf ~/rpmbuild/BUILDROOT/${tengine_version}-1.el7.ngx.x86_64/etc/sysconfig/nginx-debug
rm -rf ~/rpmbuild/BUILDROOT/${tengine_version}-1.el7.ngx.x86_64/usr/sbin/nginx-debug
rm -rf ~/rpmbuild/BUILDROOT/${tengine_version}-1.el7.ngx.x86_64/usr/share/doc/

sed -i "s/worker_processes  1;/worker_processes  auto;/g" ~/rpmbuild/BUILDROOT/${tengine_version}-1.el7.ngx.x86_64/etc/nginx/nginx.conf
sed -i "s/Description=nginx/Description=tengine/g" ~/rpmbuild/BUILDROOT/${tengine_version}-1.el7.ngx.x86_64/usr/lib/systemd/system/nginx.service
sed -i "s@http://nginx.org/en/docs/@http://tengine.taobao.org/@g" ~/rpmbuild/BUILDROOT/${tengine_version}-1.el7.ngx.x86_64/usr/lib/systemd/system/nginx.service

cd ~/rpmbuild/SPECS
if [ ! -f "tengine.spec" ]; then
    cp $PROJECT_DIR/tengine.spec ./
fi

cd ~/rpmbuild
rpmbuild -bb SPECS/tengine.spec

rm -rf ~/${tengine_version}

mv ~/rpmbuild/RPMS/x86_64/${tengine_version}-1.el7.ngx.x86_64.rpm ~/

echo "执行 yum localinstall ~/${tengine_version}-1.el7.ngx.x86_64.rpm 安装 tengine"
