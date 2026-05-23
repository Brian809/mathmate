// Stub file for Web - dart:io is not available on Web
// This file replaces dart:io imports when compiling to Web

class File {
  File(String path);
  Future<bool> exists() async => false;
  Future<void> delete() async {}
}

class Directory {
  Directory(String path);
}

class IOException implements Exception {}