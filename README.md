# Phosyn
Backup and view your photos on your server
Phosyn keeps your photos on your own server. The Android app connects to your server, while desktop and tray apps can access the same photo library.

# Releases - Binaries
Phosyn Server_0.1.0_x64_en-US.msi
=> https://github.com/kostfos/photo-synch/releases#release-phosyn_0_1_0
Includes server, desktop client, tray app to configure server

postgresql-18.6-1-windows-x64-binaries.zip
=> https://github.com/kostfos/photo-synch/releases#release-postgresql_18.6.1
Required for server to run

metai.zip
=> https://github.com/kostfos/photo-synch/releases#release-metai
Optional: AI feature add on

phosyn_10.apk
=> https://github.com/kostfos/photo-synch/releases#release-android_1_0
Please install Android client from official GooglePlayStore for latest


# How to install
Please download Phosyn Server_0.1.0_x64_en-US.msi and click to install
Phosyn server requires database app (PostgreSQL) to configure user based storage of photos and videos
Download portable binary from official site or from releases.
=> https://www.enterprisedb.com/download-postgresql-binaries
Example: 18.6 windows version: postgresql-18.6-1-windows-x64-binaries.zip
Simply unzip this to a folder where you use; do not need to configure it as phosyn server will configure it with admin password you choose in tray app; 
just point to where it is extracted.
Example: C:\Users\<USER>\pgsql\bin

Optional -- metai:
Phosyn server optionally can use AI features on photos using metai; you can enable in tray app
Go to github releases/metai to download metai.zip and metai_install.ps1
Run metai_install.ps1 and it will install metai to C:\Users\<USER>\AppData\Local\Phosyn\metai
Make sure phosyn tray app is configured to use metai with its installed folder

# How to configure tray app:
At first run tray app wizard asks you to configure:
Set location of PostgreSQL
Set location of other required locations
Set network interface to run; for android app use the actual IP 192.168...
Optional: Enable metai and set location of metai

Click start:
You will see PostgreSQL and Phosyn server are running as service; i.e. no GUI for those
In case their status is not green stop and rerun make sure installation of PostgreSQL is correct and network IP is correct.

# How to use with client apps
You will see Phosyn server running in Windows tray on the right bottom.
From there you can run "Open Phosyn" which will run desktop client; you can run this too from shortcut created in desktop.
At fresh install you will have "admin" as only user, log in with "admin" with the password you configured and create new users.
You can do this step with Android client as well with admin.
Then each user can backup and view their images and videos.

# Tray wizard for configuration
<img width="519" height="702" alt="tray_wizard_storage" src="https://github.com/user-attachments/assets/9a59ee94-8d0d-4621-aa93-92f629250d1b" />
<img width="523" height="701" alt="tray_wizard_database" src="https://github.com/user-attachments/assets/fd3dbdae-1542-4c30-9b4f-aaf430e92edf" />
<img width="521" height="700" alt="tray_wizard_server" src="https://github.com/user-attachments/assets/55c1ae80-57e9-48db-b0ec-11dc1b366471" />
<img width="522" height="701" alt="tray_wizard_admin" src="https://github.com/user-attachments/assets/db8c5296-d520-4bd1-be07-6e3dfe2c87c5" />

# Desktop client
<img width="580" height="742" alt="desk_login" src="https://github.com/user-attachments/assets/df534665-a6f8-4357-b0a2-6ff88c6a225d" />
<img width="1384" height="661" alt="desk_gallery" src="https://github.com/user-attachments/assets/b46fb74c-7d15-46d7-a1f1-f736d10e7fa1" />

# Android client
<img width="1344" height="2992" alt="login" src="https://github.com/user-attachments/assets/71e1e318-e390-4789-8ae1-05ce3600a6c6" />
<img width="1344" height="2992" alt="gallery-all" src="https://github.com/user-attachments/assets/738a9f86-f4fc-4fab-a6bb-f78550a7f5c5" />
<img width="1344" height="2992" alt="all-search" src="https://github.com/user-attachments/assets/7cb82941-1945-4a24-9ce4-46fd5b3da3b7" />
<img width="1344" height="2992" alt="album_favorites" src="https://github.com/user-attachments/assets/4c3a4de7-cf09-4281-940f-b35300cc8e89" />
<img width="1344" height="2992" alt="backup" src="https://github.com/user-attachments/assets/424a3a11-ce3d-46c7-8ec6-0fcf78fb6740" />
<img width="1344" height="2992" alt="profile" src="https://github.com/user-attachments/assets/0a29e76a-bbf2-42c1-9d80-1d91efcddeeb" />













=> minisign -Vm .\sha256_phosynserver.txt -x .\sha256_phosynserver.txt.minisig -p .\minisign.pub
=========================================
