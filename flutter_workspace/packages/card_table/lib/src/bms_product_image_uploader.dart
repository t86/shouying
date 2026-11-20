import 'package:dio/dio.dart';
import 'package:card_table/src/bms_product_image.dart';

/// Separate client: never attach tk/stk, API interceptors, cookies or redirects.
Future<void> uploadBmsImageToOss(
  BmsImageSignature signature,
  String filename,
  BmsProductImageFile file, {
  HttpClientAdapter? adapter,
}) async {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  if (adapter != null) dio.httpClientAdapter = adapter;
  try {
    final response = await dio.post<Object?>(
      signature.host.toString(),
      data: FormData.fromMap({
        ...signature.fields(filename),
        'file': MultipartFile.fromBytes(
          file.bytes,
          filename: filename,
          contentType: DioMediaType(
            'image',
            file.extension == 'png' ? 'png' : 'jpeg',
          ),
        ),
      }),
      options: Options(
        followRedirects: false,
        maxRedirects: 0,
        responseType: ResponseType.plain,
        validateStatus: (status) => status == 200,
      ),
    );
    if (response.statusCode != 200) throw const FormatException('图片上传未成功');
  } finally {
    dio.close(force: true);
  }
}
