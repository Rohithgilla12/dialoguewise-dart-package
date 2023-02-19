import 'package:dialogue_wise/DTOs/dialoguewise_request.dart';

///Creates a UploadMediaRequest payload uploads a media file.
class UploadMediaRequest extends DialoguewiseRequest {
  ///Sets the path to the file on local device that needs to be uploaded.
  String localFilePath = '';
  List<int> fileData = [];
  String? mimeType;
}
