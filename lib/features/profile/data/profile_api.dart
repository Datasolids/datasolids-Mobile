// Profile API client — wraps GET /me/ and PATCH /me/.

import 'package:datasolids_mobile/core/network/dio_client.dart';
import 'package:datasolids_mobile/features/profile/data/dtos/user_profile_dto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileApi {
  ProfileApi(this._dio);
  final Dio _dio;

  Future<UserProfile> getMe() async {
    final resp = await _dio.get<Map<String, dynamic>>('/auth/me/');
    return UserProfile.fromJson(resp.data ?? const {});
  }

  Future<UserProfile> updateMe(Map<String, dynamic> payload) async {
    final resp = await _dio.patch<Map<String, dynamic>>(
      '/auth/me/',
      data: payload,
    );
    return UserProfile.fromJson(resp.data ?? const {});
  }

  /// Upload (or replace) the avatar. [filePath] is a local image path from
  /// image_picker. Returns the refreshed profile (with a new presigned URL).
  Future<UserProfile> uploadAvatar(String filePath) async {
    final fileName = filePath.split('/').last;
    final form = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final resp = await _dio.post<Map<String, dynamic>>(
      '/auth/me/avatar/',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return UserProfile.fromJson(resp.data ?? const {});
  }

  Future<UserProfile> removeAvatar() async {
    final resp = await _dio.delete<Map<String, dynamic>>('/auth/me/avatar/');
    return UserProfile.fromJson(resp.data ?? const {});
  }
}

final profileApiProvider = Provider<ProfileApi>((ref) {
  return ProfileApi(ref.watch(dioProvider));
});
