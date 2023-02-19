import 'dart:convert';
import 'dart:io';

import 'package:dialogue_wise/DTOs/add_contents_request.dart';
import 'package:dialogue_wise/DTOs/delete_content_request.dart';
import 'package:dialogue_wise/DTOs/dialoguewise_response.dart';
import 'package:dialogue_wise/DTOs/get_contents_request.dart';
import 'package:dialogue_wise/DTOs/get_variables_request.dart';
import 'package:dialogue_wise/DTOs/search_contents_request.dart';
import 'package:dialogue_wise/DTOs/update_content_request.dart';
import 'package:dialogue_wise/DTOs/upload_media_request.dart';
import 'package:dialogue_wise/constants/endpoints.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

///Allows you to manage your content using Dialoguewise Headless CMS
class DialoguewiseService {
  String _apiBaseUrl = '';
  final String accessToken;

  late Dio _dio;

  DialoguewiseService({
    String? apiBaseUrl,
    required this.accessToken,
  }) : assert(accessToken.isNotEmpty, "Please provide the access token.") {
    if (apiBaseUrl != null && apiBaseUrl.isNotEmpty) {
      _apiBaseUrl = (apiBaseUrl[apiBaseUrl.length - 1] != '/'
              ? (apiBaseUrl + "/")
              : apiBaseUrl) +
          "api/";
    } else {
      _apiBaseUrl = '';
    }
    _dio = Dio(
      BaseOptions(
          baseUrl: apiBaseUrl ?? 'https://api.dialoguewise.com/api/',
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': '*',
            'Access-Control-Allow-Headers': 'Content-Type, Access-Token',
            'Content-Type': 'application/json',
            'Access-Token': accessToken,
          }),
    );
  }

  String get apiBaseUrl {
    if (_apiBaseUrl.isEmpty) {
      return 'https://api.dialoguewise.com/api/';
    }

    return _apiBaseUrl;
  }

  ///Gets all the published Dialogues in a project.
  ///Takes parameter [accessToken] of type String as access token.
  ///Returns a [DialoguewiseResponse] object.
  ///Throws [FormatException] if the access token is empty.
  /// Example:
  /// ```dart
  /// final dialogueWiseService = DialoguewiseService(
  ///   accessToken: '<Provide access token>',
  /// );
  ///
  /// final res = await dialogueWiseService.getDialogues();
  Future<DialoguewiseResponse> getDialogues() async {
    final RequestOptions clientRequest =
        _getRequest(Endpoints.getDialogues, isGet: true);

    return _getResponse(clientRequest);
  }

  ///Gets all the Variables of a published Dialogue.
  ///Takes parameter [request] of type GetVariablesRequest.
  Future<DialoguewiseResponse> getVariables(GetVariablesRequest request) async {
    if (request.slug.isEmpty) {
      throw FormatException("Please provide the Slug.");
    }

    final clientRequest = _getRequest(
      '${Endpoints.getVariables}?slug=${request.slug}',
      isGet: true,
    );

    return _getResponse(clientRequest);
  }

  ///Gets all the contents in a dialogue.
  ///Takes parameter [request] of type GetContentsRequest.
  Future<DialoguewiseResponse> getContents(GetContentsRequest request) async {
    if (request.slug.isEmpty) {
      throw FormatException("Please provide a Slug.");
    } else if ((request.pageSize == null && request.pageIndex != null) ||
        (request.pageSize != null && request.pageIndex == null)) {
      throw FormatException("Please set both pageSize and pageIndex");
    }

    final RequestOptions clientRequest =
        _getRequest(Endpoints.getContents, data: request);

    return _getResponse(clientRequest);
  }

  ///Gets all the contents in a dialogue that matches the search keyword.
  ///Takes [request] of type SearchContentsRequest.
  Future<DialoguewiseResponse> searchContents(
      SearchContentsRequest request) async {
    if (request.slug.isEmpty) {
      throw FormatException("Please provide a Slug.");
    }

    final clientRequest = _getRequest(Endpoints.searchContents, data: request);

    return _getResponse(clientRequest);
  }

  ///Adds content to a dialogue.
  ///Takes [request] of type AddContentsRequest.
  Future<DialoguewiseResponse> addContents(AddContentsRequest request) async {
    if (request.slug.isEmpty) {
      throw FormatException("Please provide a Slug.");
    } else if (request.contents.isEmpty) {
      throw FormatException("Please provide the contents to be added.");
    } else if (request.source.isEmpty) {
      throw FormatException("Please provide a source name.");
    }

    final clientRequest = _getRequest(Endpoints.addContents, data: request);

    return _getResponse(clientRequest);
  }

  ///Update exisitng content.
  ///Takes [request] of type UpdateContentRequest.
  Future<DialoguewiseResponse> updateContent(
      UpdateContentRequest request) async {
    if (request.slug.isEmpty) {
      throw FormatException("Please provide a Slug.");
    } else if (request.content.fields.isEmpty) {
      throw FormatException("Please provide the contents to be added.");
    } else if (request.content.id == null || request.content.id!.isEmpty) {
      throw FormatException("Please provide content id.");
    } else if (request.source.isEmpty) {
      throw FormatException("Please provide a source name.");
    }

    final clientRequest = _getRequest(Endpoints.updateContent, data: request);

    return _getResponse(clientRequest);
  }

  ///Delete exisitng content.
  ///Takes [request] of type DeleteContentRequest.
  Future<DialoguewiseResponse> deleteContent(
    DeleteContentRequest request,
  ) async {
    if (request.slug.isEmpty) {
      throw FormatException("Please provide a Slug.");
    } else if (request.contentId.isEmpty) {
      throw FormatException("Please provide the content id.");
    } else if (request.source.isEmpty) {
      throw FormatException("Please provide a source name.");
    }

    final clientRequest = _getRequest(Endpoints.deleteContent, data: request);

    return _getResponse(clientRequest);
  }

  ///Uploads an image or file and returns the file URL.
  ///Takes [request] of type UploadMediaRequest.
  Future<DialoguewiseResponse> uploadMedia(UploadMediaRequest request) async {
    if (request.fileData.isEmpty && request.localFilePath.isEmpty) {
      throw FormatException(
          "Please provide the local path of file to be uploaded.");
    }

    if (request.fileData.isEmpty && request.localFilePath.isNotEmpty) {
      if ((Platform.isAndroid || Platform.isIOS) &&
          FileSystemEntity.typeSync(request.localFilePath) ==
              FileSystemEntityType.notFound) {
        throw FormatException("Unable to find file ${request.localFilePath}.");
      }
    }

    final fileName = request.localFilePath.isNotEmpty
        ? request.localFilePath.split('/').last
        : 'image.png';

    List<String> mediaType = [];

    if (request.fileData.isNotEmpty && request.mimeType == null) {
      throw FormatException("Please provide the mime type of the file.");
    }

    if (request.fileData.isNotEmpty) {
      mediaType = request.mimeType!.split('/');
    }

    final Response<String> response = await _dio.fetch(
      RequestOptions(
        path: '${apiBaseUrl}dialogue/uploadmedia',
        method: 'POST',
        headers: {
          'Access-Control-Allow-origin': '*',
          'Access-Control-Allow-Methods': '*',
          'Access-Control-Allow-Headers': 'Content-Type, Access-Token',
          'Access-Token': accessToken,
        },
        data: FormData.fromMap(
          {
            'file': request.fileData.isNotEmpty
                ? MultipartFile.fromBytes(
                    request.fileData,
                    contentType: MediaType(
                      mediaType.first,
                      mediaType.last,
                    ),
                    filename: '$fileName.${mediaType.last}',
                  )
                : await MultipartFile.fromFile(
                    request.localFilePath,
                  ),
          },
        ),
        contentType: 'multipart/form-data',
      ),
    );

    DialoguewiseResponse dialogueWiseResponse = DialoguewiseResponse(
      reasonPhrase: response.statusMessage ?? 'Something went wrong.',
      statusCode: response.statusCode ?? 500,
    );
    final responseBody = jsonDecode(response.data ?? '{}');

    if (responseBody.isNotEmpty) {
      dialogueWiseResponse = dialogueWiseResponse.copyWith(
        response: responseBody as Map<String, dynamic>,
      );
    }

    return dialogueWiseResponse;
  }

  Future<DialoguewiseResponse> _getResponse(
      RequestOptions clientRequest) async {
    final Response<String> response = await _dio.fetch(clientRequest);
    final responseBody = response.data;
    _dio.close();

    DialoguewiseResponse dialogueWiseResponse = DialoguewiseResponse(
      reasonPhrase: response.statusMessage ?? 'Something went wrong.',
      statusCode: response.statusCode ?? 500,
    );

    if (responseBody?.isNotEmpty == true) {
      try {
        dialogueWiseResponse = dialogueWiseResponse.copyWith(
          response: jsonDecode(responseBody ?? '{}') as Map<String, dynamic>,
        );
      } catch (e) {
        final Map<String, dynamic> errorResponse = {
          'error': 'Invalid server response.',
        };
        dialogueWiseResponse.response = errorResponse;
      }
    }

    return dialogueWiseResponse;
  }

  RequestOptions _getRequest(
    String apiRoute, {
    dynamic data,
    bool isGet = false,
  }) {
    final requestOptions = RequestOptions(
      path: '$apiBaseUrl$apiRoute',
      method: isGet ? 'GET' : 'POST',
      data: jsonEncode(data),
      headers: {
        'Access-Control-Allow-origin': '*',
        'Access-Control-Allow-Methods': '*',
        'Access-Control-Allow-Headers': 'Content-Type, Access-Token',
        'Content-Type': 'application/json',
        'Access-Token': accessToken,
      },
    );

    return requestOptions;
  }
}
