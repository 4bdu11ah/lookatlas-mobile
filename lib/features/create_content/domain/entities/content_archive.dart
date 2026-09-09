import 'dart:typed_data';

class ContentExportTicket {
  const ContentExportTicket({required this.url, required this.fileName});

  final Uri url;
  final String fileName;
}

class ContentArchive {
  const ContentArchive({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}
