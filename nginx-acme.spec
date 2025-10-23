Name:           nginx-acme
Version:        1.0.0
Release:        1%{?dist}
Summary:        Standalone NGINX ACME Certificate Manager

License:        MIT
URL:            https://your-company.com/nginx-acme
Source0:        nginx-acme-%{version}.tar.gz

BuildRequires:  python3-devel
BuildRequires:  python3-setuptools
Requires:       python3
Requires:       nginx
Requires:       openssl
# Note: NO certbot dependency - nginx-acme is self-contained

%description
Standalone NGINX ACME Certificate Manager for Rocky Linux 9.
Handles ACME protocol directly without requiring certbot or acme.sh.

%prep
%setup -q

%build
%py3_build

%install
%py3_install
mkdir -p %{buildroot}%{_sysconfdir}/nginx-acme
mkdir -p %{buildroot}%{_sharedstatedir}/nginx-acme/challenges/.well-known/acme-challenge
mkdir -p %{buildroot}%{_unitdir}

%files
%{python3_sitelib}/*
%{_bindir}/nginx-acme
%dir %{_sysconfdir}/nginx-acme
%dir %{_sharedstatedir}/nginx-acme
%dir %{_sharedstatedir}/nginx-acme/challenges
%{_unitdir}/nginx-acme.service

%pre
getent group nginx-acme >/dev/null || groupadd -r nginx-acme
getent passwd nginx-acme >/dev/null || \
    useradd -r -g nginx-acme -d /opt/nginx-acme -s /sbin/nologin nginx-acme

%post
%systemd_post nginx-acme.service

%preun
%systemd_preun nginx-acme.service

%postun
%systemd_postun_with_restart nginx-acme.service