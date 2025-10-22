# Enable with systemctl
%global _with_systemd 1

Name:		   backoid
%if "0%{?_version}" == "0"
Version:       1.2
%else
Version:       %{_version}
%endif
%if "0%{?_release}" == "0"
Release:	   1
%else
Release:	   %{_release}
%endif
BuildArch:	   noarch
Summary:	   A sanoid/syncoid-like utility for object storage backup targets
Group:		   Applications/System
License:	   GPLv3
URL:		   https://github.com/shatteredsilicon/%{name}
Source0:	   https://github.com/shatteredsilicon/%{name}/archive/v%{version}/%{name}-%{version}.tar.gz

Requires:	   perl, mbuffer, lzop, pv, perl-Config-IniFiles, perl-Capture-Tiny, perl-Number-Bytes-Human, perl-Parallel-ForkManager, zstd, rclone, tar, lz4
%if 0%{?_with_systemd}
Requires:      systemd >= 212

BuildRequires: systemd
%endif

%description
Backoid is a sanoid/syncoid-like utility
for object storage backup targets.

%prep
%setup -q

%build
echo "Nothing to build"

%install
%{__install} -D -m 0644 backoid.defaults.conf %{buildroot}/etc/backoid/backoid.defaults.conf
%{__install} -d %{buildroot}/usr/sbin
%{__install} -m 0755 backoid %{buildroot}/usr/sbin/

%if 0%{?_with_systemd}
%{__install} -d %{buildroot}/lib/systemd/system
%{__install} -m 0644 backoid.service backoid.timer %{buildroot}/lib/systemd/system/
%endif

%if 0%{?fedora}
%{__install} -D -m 0644 backoid.conf %{buildroot}%{_docdir}/%{name}/examples/backoid.conf
%endif
%if 0%{?rhel}
%{__install} -D -m 0644 backoid.conf %{buildroot}%{_docdir}/%{name}-%{version}/examples/backoid.conf
%endif

%if 0%{?_with_systemd}
%else
%if 0%{?fedora}
echo "* * * * * root /usr/sbin/backoid" > %{buildroot}%{_docdir}/%{name}/examples/backoid.cron
%endif
%if 0%{?rhel}
echo "* * * * * root /usr/sbin/backoid" > %{buildroot}%{_docdir}/%{name}-%{version}/examples/backoid.cron
%endif
%endif

%post
%if 0%{?_with_systemd}
%systemd_post backoid.service
%systemd_post backoid.timer
%endif

%preun
%if 0%{?_with_systemd}
%systemd_preun backoid.service
%systemd_preun backoid.timer
%endif

%postun
%if 0%{?_with_systemd}
%systemd_postun backoid.service
%systemd_postun backoid.timer
%endif

%files
%doc README.md
%license LICENSE
/usr/sbin/backoid
%dir %{_sysconfdir}/%{name}
%config %{_sysconfdir}/%{name}/backoid.defaults.conf
%if 0%{?fedora}
%{_docdir}/%{name}
%endif
%if 0%{?rhel}
%{_docdir}/%{name}-%{version}
%endif
%if 0%{?_with_systemd}
/lib/systemd/system/%{name}.service
/lib/systemd/system/%{name}.timer
%endif

%changelog
* Sat Jul 28 2023 Jason Ng <oblitorum@gmail.com> - 1.0-1
- Initial RPM Package
