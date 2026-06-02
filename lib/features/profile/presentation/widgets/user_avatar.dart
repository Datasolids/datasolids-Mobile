// Reusable circular avatar. Shows the user's S3 profile picture (via a
// presigned URL) when present, otherwise falls back to initials on a navy
// disc. Used in the home header, nav drawer, profile tab, etc.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/profile/data/dtos/user_profile_dto.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.user,
    this.size = 48,
    this.borderWidth = 2,
  });

  final UserProfile? user;
  final double size;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final url = user?.avatarUrl;
    final initials = user?.initials ?? '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.navy900,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.teal500, width: borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: (url != null && url.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, __) => _Initials(initials, size),
              errorWidget: (_, __, ___) => _Initials(initials, size),
            )
          : _Initials(initials, size),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials(this.initials, this.size);
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      initials,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: size * 0.3,
      ),
    );
  }
}
