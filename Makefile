BUILDDIR	?= /tmp/ssmbuild
VERSION		?= $(shell rpmspec -q --queryformat="%{version}" backoid.spec)
RELEASE		?= 1

.PHONY: all
all:

ifeq (0, $(shell hash dpkg 2>/dev/null; echo $$?))
ARCH	:= $(shell dpkg --print-architecture)
all: sdeb deb
else
ARCH	:= $(shell rpm --eval "%{_arch}")
all: srpm rpm
endif

TARBALL_FILE	:= $(BUILDDIR)/tarballs/backoid-$(VERSION)-$(RELEASE).tar.gz
SRPM_FILE		:= $(BUILDDIR)/results/SRPMS/backoid-$(VERSION)-$(RELEASE).src.rpm
RPM_FILES		:= $(BUILDDIR)/results/RPMS/backoid-$(VERSION)-$(RELEASE).noarch.rpm
SDEB_FILES		:= $(BUILDDIR)/results/SDEBS/backoid_$(VERSION)-$(RELEASE).dsc $(BUILDDIR)/results/SDEBS/backoid_$(VERSION)-$(RELEASE).tar.gz
DEB_FILES		:= $(BUILDDIR)/results/DEBS/backoid_$(VERSION)-$(RELEASE)_all.deb $(BUILDDIR)/results/DEBS/backoid_$(VERSION)-$(RELEASE)_$(ARCH).changes

$(TARBALL_FILE):
	mkdir -vp $(shell dirname $(TARBALL_FILE))

	tar --exclude='Makefile' --exclude-vcs -czf $(TARBALL_FILE) -C $(shell dirname $(CURDIR)) --transform s/^$(shell basename $(CURDIR))/backoid/ $(shell basename $(CURDIR))

.PHONY: srpm
srpm: $(SRPM_FILE)

$(SRPM_FILE): $(TARBALL_FILE)
	mkdir -vp $(BUILDDIR)/rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
	mkdir -vp $(shell dirname $(SRPM_FILE))

	cp backoid.spec $(BUILDDIR)/rpmbuild/SPECS/backoid.spec
	sed -i -E "s/%\{\??_version\}/$(VERSION)/g" "$(BUILDDIR)/rpmbuild/SPECS/backoid.spec"
	sed -i -E "s/%\{\??_release\}/$(RELEASE)/g" "$(BUILDDIR)/rpmbuild/SPECS/backoid.spec"
	cp $(TARBALL_FILE) $(BUILDDIR)/rpmbuild/SOURCES/
	spectool -C $(BUILDDIR)/rpmbuild/SOURCES/ -g $(BUILDDIR)/rpmbuild/SPECS/backoid.spec
	rpmbuild -bs --define "debug_package %{nil}" --define "_topdir $(BUILDDIR)/rpmbuild" $(BUILDDIR)/rpmbuild/SPECS/backoid.spec
	mv $(BUILDDIR)/rpmbuild/SRPMS/$(shell basename $(SRPM_FILE)) $(SRPM_FILE)

.PHONY: rpm
rpm: $(RPM_FILES)

$(RPM_FILES): $(SRPM_FILE)
	mkdir -vp $(BUILDDIR)/mock
	mock -r oraclelinux-7-$(ARCH) --resultdir $(BUILDDIR)/mock --rebuild $(SRPM_FILE)

	for rpm_file in $(RPM_FILES); do \
		mkdir -vp $$(dirname $${rpm_file}); \
		mv $(BUILDDIR)/mock/$$(basename $${rpm_file}) $${rpm_file}; \
	done

.PHONY: sdeb
sdeb: $(SDEB_FILES)

$(SDEB_FILES): $(TARBALL_FILE)
	mkdir -vp $(BUILDDIR)/debbuild/SDEB/backoid-$(VERSION)-$(RELEASE)
	cp -r debian $(BUILDDIR)/debbuild/SDEB/backoid-$(VERSION)-$(RELEASE)/

	cd $(BUILDDIR)/debbuild/SDEB/backoid-$(VERSION)-$(RELEASE)/; \
		tar -zxf $(TARBALL_FILE) --strip-components=1; \
		sed "s/%{_version}/$(VERSION)/g" debian/control > debian/.control && mv debian/.control debian/control; \
		sed "s/%{_release}/$(RELEASE)/g" debian/control > debian/.control && mv debian/.control debian/control; \
		sed "s/%{_version}/$(VERSION)/g" debian/rules > debian/.rules && mv debian/.rules debian/rules; \
		sed "s/%{_release}/$(RELEASE)/g" debian/rules > debian/.rules && mv debian/.rules debian/rules; \
		sed "s/%{_version}/$(VERSION)/g" debian/changelog > debian/.changelog && mv debian/.changelog debian/changelog; \
		sed "s/%{_release}/$(RELEASE)/g" debian/changelog > debian/.changelog && mv debian/.changelog debian/changelog; \
		dpkg-buildpackage -S -us

	for sdeb_file in $(SDEB_FILES); do \
		mkdir -vp $$(dirname $${sdeb_file}); \
		mv -f $(BUILDDIR)/debbuild/SDEB/$$(basename $${sdeb_file}) $${sdeb_file}; \
	done

.PHONY: deb
deb: $(DEB_FILES)

$(DEB_FILES): $(SDEB_FILES)
	mkdir -vp $(BUILDDIR)/debbuild/DEB/backoid-$(VERSION)-$(RELEASE)
	for sdeb_file in $(SDEB_FILES); do \
		cp -r $${sdeb_file} $(BUILDDIR)/debbuild/DEB/backoid-$(VERSION)-$(RELEASE)/; \
	done

	cd $(BUILDDIR)/debbuild/DEB/backoid-$(VERSION)-$(RELEASE)/; \
		rm -rf backoid-$(VERSION); \
		dpkg-source -x -sp backoid_$(VERSION)-$(RELEASE).dsc; \
		cd backoid-$(VERSION); \
			dpkg-buildpackage -b -uc

	for deb_file in $(DEB_FILES); do \
		mkdir -vp $$(dirname $${deb_file}); \
		mv -f $(BUILDDIR)/debbuild/DEB/backoid-$(VERSION)-$(RELEASE)/$$(basename $${deb_file}) $${deb_file}; \
	done

.PHONY: clean
clean:
	rm -rf $(BUILDDIR)/{tarballs,rpmbuild,mock,results}