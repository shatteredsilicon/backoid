# backoid
backoid - a sanoid/syncoid-like utility for object storage backup targets

## Installation

### By building package and install it

#### DEB-based system

Install prerequisite software:

```bash
sudo apt install debhelper libcapture-tiny-perl libconfig-inifiles-perl pv zstd build-essential git rclone
```

Clone this repo, `cd` into it and checkout the source code of latest stable release

```bash
git clone https://github.com/shatteredsilicon/backoid.git && \
cd backoid && \
git checkout $(git tag | grep "^v" | tail -n 1)
```

Build the package

```bash
dpkg-buildpackage -uc -us
```

Install the package

```bash
sudo apt install ../backoid_*_all.deb
```

#### RPM-based system

Install prerequisite software:

```bash
sudo yum install git yum-utils rpmdevtools perl-Config-IniFiles perl-Data-Dumper perl-Capture-Tiny perl-Getopt-Long pv rclone zstd gzip
```

Clone this repo, `cd`` into it and checkout the source code of latest stable release

```bash
git clone https://github.com/shatteredsilicon/backoid.git && \
cd backoid && \
git checkout $(git tag | grep "^v" | tail -n 1)
```

Prepare directories for rpm build

```bash
mkdir -p ~/rpmbuild/SOURCES
```

Create source code tarball by downloading it

```bash
spectool -C ~/rpmbuild/SOURCES -g backoid.spec
```

Or by taring up local repo

```bash
backoid_version="$(git tag | grep "^v" | tail -n 1)" && \
tar -czf ~/rpmbuild/SOURCES/backoid-${backoid_version#v}.tar.gz -C $(dirname $(pwd)) --transform "s/backoid/backoid-${backoid_version#v}/" backoid
```

Build the package

```bash
rpmbuild -ba backoid.spec
```

Install the package

```bash
sudo yum install ~/rpmbuild/RPMS/noarch/backoid-*.rpm
```

### By manually install

Clone this repo, `cd`` into it and checkout the source code of latest stable release

```bash
git clone https://github.com/shatteredsilicon/backoid.git && \
cd backoid && \
git checkout $(git tag | grep "^v" | tail -n 1)
```

Put the executables and config files into the appropriate directories:

```bash
# Install the executables
sudo cp backoid /usr/local/sbin
# Create the config directory
sudo mkdir /etc/backoid
# Install default config
sudo cp backoid.defaults.conf /etc/backoid/
# Create a blank config file
sudo touch /etc/backoid/backoid.conf
# Place the sample config in the conf directory for reference
sudo cp backoid.conf /etc/backoid/backoid.example.conf
```

Create a systemd service:

```bash
cat << "EOF" | sudo tee /etc/systemd/system/backoid.service
[Unit]
Description=Backup ZFS snapshots
Requires=zfs.target
After=zfs.target

[Service]
Environment=TZ=UTC
Type=oneshot
ExecStart=/usr/sbin/backoid
EOF
```

And a systemd timer that will execute **Backoid** once per quarter hour
(Decrease the interval as suitable for configuration):

```bash
cat << "EOF" | sudo tee /etc/systemd/system/backoid.timer
[Unit]
Description=Run Backoid Every 15 Minutes
Requires=backoid.service

[Timer]
OnCalendar=*:0/15
Persistent=true

[Install]
WantedBy=timers.target
EOF
```

Reload systemd:
```bash
# Tell systemd about our new service definitions
sudo systemctl daemon-reload
```

## Configuration

Before you run **backoid**, you need to tell it how to handle the backups by configuring the `/etc/backoid/backoid.conf` file. Below is an example of the `/etc/backoid/backoid.conf` file:

```conf
[zpoolname/production]
	use_template = production

[template_production]
	pattern = ^production_.*
	compression = zstd
	compression_level = 3
	target = s3:production/
	retention = 7d

[zpoolname/demo]
	pattern = ^demo_.*
	compression = gzip
	compression_level = 9
	retention = 7
	target = s3:demo/
```

And the definition for each option is:

+	pattern

	This is an regex match pattern, **Backoid** uses this pattern to match the name of ZFS snapshot, only the matched snapshots will be processed. An example value for this option is:

	```
	pattern = ^autosnap_.*
	```

+	compression

	This option indicates which compression algorithm will be used to compress the tarball of snapshots. Available options are `bzip2, gzip, lz4, pbzip2, pigz, zstd, pzstd, pxz, xz`.

+	compression_level

	This option indicates what compression level is used during the compression. Default to whatever is default for the compressor.

+	target

	This option is for **rclone**, indicates where does the backup upload to. e.g. `s3:backoid/`.

+   retention

    The duration/amount of that snapshots are keeping in the remote with. Format is in `number[h/d/w/m/y]`, the meaning of those suffix is:

    ```
    h -> hour
    d -> day
    w -> week
    m -> month
    y -> year
    ```

    e.g. `retention = 7d`, `retention = 2w`, etc.

    When the suffix is empty, it means to keep only the **X** most recent snapshots that matches the pattern.

+	compressor_options

	options that will be passed directly to the compressor program. e.g. `compressor_options = --threads=24`

+	rclone_options

	options that will be passed directly to the rclone program during the upload. e.g. `rclone_options = --buffer-size=32M`

And below are the available command line arguments:

+   --configdir

	Specify a location for the config file named backoid.conf. Defaults to /etc/backoid

+   --run-dir

	Specify a directory for temporary files such as lock files. Defaults to /var/run/backoid

+   --verbose

	This prints additional information during the backoid run.

+   --debug

	This prints out quite a lot of additional information during a backoid run, and is normally not needed.

# Run

Just start the backoid timer

```bash
sudo systemctl enable --now backoid.timer
```
