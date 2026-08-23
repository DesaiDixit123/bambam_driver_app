import 'package:http_parser/src/media_type.dart' as media_type;

class ImageFormData {
  ImageFormData(
      {required this.fieldName,
      required this.filePath,
      required this.mediaType});
  String fieldName;
  String filePath;
  media_type.MediaType mediaType;
}
