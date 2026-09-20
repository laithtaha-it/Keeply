# Keeply

Keeply is a Flutter application for managing personal passwords, bookmarks, media, documents, and folders in one local vault.

The application is designed to work primarily with locally stored data, with Google Drive integration available for backup and restore.

> **Current testing:** Keeply has currently been tested on **Android**. Other platforms are included in the Flutter project configuration, but their functionality has not been fully tested and should not be considered verified.

---

## Features

### 🔐 PIN-protected vault

Keeply uses a PIN-based authentication flow to protect access to the vault.

The PIN is securely stored and verified using a password-based key derivation process.

---

### 🔑 Passwords

The vault allows users to store password entries containing:

* Username / email
* Password
* Description / notes

Password entries can be:

* Added
* Edited
* Deleted
* Hidden or revealed
* Copied to the clipboard

---

### 🔗 Bookmarks

Keeply includes a bookmark manager for storing website links.

Bookmarks support:

* URL
* Description
* Creation date
* Last updated date

Users can:

* Add bookmarks
* Edit bookmarks
* Delete bookmarks
* Open saved URLs
* Copy URLs

URLs are validated and normalized before being stored.

---

### 🖼️ Media

Keeply can import media files and manage them from inside the application.

The media functionality includes:

* Importing one or multiple files
* Previewing images
* Opening media
* Sharing media
* Saving supported media to the device gallery
* Deleting media

Media metadata is stored locally, while the imported media files are stored in the application's local storage.

---

### 📁 Files and folders

Keeply provides a file manager with folder organization.

Users can:

* Create folders
* Navigate between folders
* Create nested folders
* Import multiple files
* Open files
* Share files
* Delete files
* Delete folders when allowed

The application contains handling for several document formats, including:

* PDF
* Images
* TXT
* DOCX
* XLSX
* PPTX

PDF files can be viewed using the integrated PDF viewer.

Other supported document formats have application-level handling for reading or previewing their contents where implemented. Files that require an external application can be opened through the device's available applications.

---

## ☁️ Google Drive Backup

Keeply includes Google Drive integration for backing up and restoring vault data.

The backup system stores different types of application data separately, including:

```text
Keeply_Vault_
Keeply_Bookmark_
Keeply_Folder_
Keeply_MediaMeta_
Keeply_MediaData_
Keeply_FileMeta_
Keeply_FileData_
```

This separates vault records, bookmarks, folders, media metadata, media files, file metadata, and file data within Google Drive.

---

## 🔄 Incremental Backup

The Google Drive backup implementation compares local data with the existing cloud data.

SHA-256 hashes are used when determining whether stored data has changed.

The synchronization process can:

* Upload new data
* Update changed data
* Skip unchanged data
* Remove obsolete backup objects

Backup operations use limited concurrency, with up to three operations running at the same time.

The backup process also tracks information such as:

* Created items
* Updated items
* Skipped items
* Deleted items
* Examined items
* Uploaded data size

---

## ♻️ Restore

Keeply supports restoring backup data from Google Drive.

The restore process is designed to add missing data to the existing local vault rather than clearing the current local data.

It can restore:

* Password entries
* Bookmarks
* Folders
* Media metadata
* Media files
* File metadata
* File data

Existing local data is kept during the restore process.

---

## 💾 Local Storage

Keeply uses **Hive** for local application data.

Separate Hive boxes are used for the main data categories:

```text
secure_vault_items
secure_vault_bookmarks
secure_vault_media
secure_vault_files
secure_vault_folders
```

The application therefore does not require an internet connection for its primary local vault operations.

Internet connectivity is required for Google Drive backup and restore operations.

---

## 🔒 Security

Keeply uses secure storage for authentication-related information.

The project also contains cryptographic functionality, including an AES-256-CBC encryption service.

The current application does **not** apply this encryption service to every Hive record or to Google Drive backup data.

Therefore, Keeply should not be described as providing fully encrypted local storage or end-to-end encrypted Google Drive backups.

---

## 🌍 Localization

Keeply currently includes:

* English
* Arabic

The application supports switching between the two languages.

Arabic uses the bundled **Tajawal** font.

The interface supports the corresponding left-to-right and right-to-left layouts.

---

## 🏗️ Project Structure

The project is organized into application features and shared services.

```text
lib/
├── app/
├── core/
│   ├── backup/
│   ├── cloud/
│   ├── constants/
│   ├── debug/
│   ├── localization/
│   ├── security/
│   ├── storage/
│   └── theme/
│
├── features/
│   ├── auth/
│   ├── backup/
│   ├── bookmarks/
│   ├── files/
│   ├── media/
│   ├── settings/
│   └── vault/
│
└── l10n/
```

The project uses Flutter and Dart with feature-based organization.

---

## 🛠️ Technologies

The project uses the following technologies and packages for its implemented functionality:

| Technology             | Usage                                    |
| ---------------------- | ---------------------------------------- |
| Flutter                | Application framework                    |
| Dart                   | Programming language                     |
| flutter_bloc           | State management                         |
| Provider               | Dependency/state access                  |
| Hive                   | Local data storage                       |
| flutter_secure_storage | Secure storage                           |
| crypto                 | Cryptographic hashing and operations     |
| encrypt                | AES encryption functionality             |
| Google Sign-In         | Google authentication                    |
| Google APIs            | Google Drive integration                 |
| file_picker            | File selection                           |
| archive                | Archive/document processing              |
| Syncfusion PDF Viewer  | PDF viewing                              |
| flutter_image_compress | Image compression                        |
| gal                    | Gallery operations                       |
| share_plus             | Sharing files and media                  |
| open_filex             | Opening files with external applications |
| url_launcher           | Opening URLs                             |

---

## 🚀 Getting Started

### Requirements

Install Flutter and make sure your Flutter environment is configured correctly.

Then install the project dependencies:

```bash
flutter pub get
```

Run the application with:

```bash
flutter run
```

To select a connected device:

```bash
flutter devices
```

Then:

```bash
flutter run -d <device>
```

---

## 📱 Testing Status

### Android

**Tested:** Yes

The current working version has been tested on Android.

### iOS

**Not fully tested**

Although the project contains iOS configuration, the current version has not been fully tested on an iPhone. Some functionality may require additional platform-specific configuration or testing.

### Windows

**Not fully tested**

The project contains Windows-related Flutter configuration, but the application has not been fully tested on Windows.

### macOS

**Not fully tested**

The project contains macOS-related Flutter configuration, but the application has not been fully tested on macOS.

### Linux

**Not fully tested**

The project contains Linux-related Flutter configuration, but the application has not been fully tested on Linux.

### Web

**Not the current tested target**

The current application testing was performed on Android. Web functionality should not be considered verified based only on the presence of Flutter web configuration.

---

## 📌 Current Status

Keeply is currently a working Flutter project with its primary testing focused on Android.

The main implemented areas are:

* PIN-protected vault
* Password management
* Bookmark management
* Local media management
* File and folder management
* Hive-based local storage
* Arabic and English localization
* Google Drive backup
* Google Drive restore

Platform-specific behavior outside Android still requires additional testing.

---

## ⚠️ Important Notes

Keeply is provided as a personal software project and its current implementation should be evaluated based on the actual source code.

In particular:

* Android is the currently tested platform.
* Other Flutter platforms have not been fully verified.
* Google Drive functionality requires the appropriate Google authentication/API configuration.
* The encryption service exists in the project but is not applied to every stored record or Google Drive backup.
* No claim of end-to-end encrypted cloud backup is made.

---

## 📄 License

No open-source license is currently specified for this project.

Until a license is added, the source code should not be assumed to be freely reusable, modified, or redistributed.
