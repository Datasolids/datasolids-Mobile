// Personal Profile — view + edit the signed-in user's details.
// Matches the "Personal Profile" Figma reference. Reads from and writes
// to the currentUserControllerProvider (GET/PATCH /api/v1/auth/me/).

import 'package:cached_network_image/cached_network_image.dart';
import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/profile/presentation/controllers/current_user_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class PersonalProfileScreen extends ConsumerStatefulWidget {
  const PersonalProfileScreen({super.key});

  @override
  ConsumerState<PersonalProfileScreen> createState() =>
      _PersonalProfileScreenState();
}

class _PersonalProfileScreenState
    extends ConsumerState<PersonalProfileScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  String? _gender;
  DateTime? _dob;

  bool _editing = false;
  bool _saving = false;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    // Make sure we have fresh data.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserControllerProvider).user;
      if (user == null) {
        ref.read(currentUserControllerProvider.notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _zipCtrl.dispose();
    super.dispose();
  }

  void _seedControllers() {
    final user = ref.read(currentUserControllerProvider).user;
    if (user == null) return;
    _firstNameCtrl.text = user.firstName;
    _lastNameCtrl.text = user.lastName;
    _phoneCtrl.text = user.phone ?? '';
    _streetCtrl.text = user.streetAddress ?? '';
    _cityCtrl.text = user.city ?? '';
    _zipCtrl.text = user.zipCode ?? '';
    _gender = user.gender;
    if (user.dateOfBirth != null && user.dateOfBirth!.isNotEmpty) {
      _dob = DateTime.tryParse(user.dateOfBirth!);
    }
    _seeded = true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final payload = <String, dynamic>{
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
      if (_gender != null) 'gender': _gender,
      if (_dob != null)
        'date_of_birth':
            '${_dob!.year.toString().padLeft(4, '0')}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
      if (_streetCtrl.text.trim().isNotEmpty)
        'street_address': _streetCtrl.text.trim(),
      if (_cityCtrl.text.trim().isNotEmpty) 'city': _cityCtrl.text.trim(),
      if (_zipCtrl.text.trim().isNotEmpty) 'zip_code': _zipCtrl.text.trim(),
    };

    final ok = await ref
        .read(currentUserControllerProvider.notifier)
        .update(payload);

    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) _editing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? AppColors.green700 : AppColors.red700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        content: Text(
          ok ? 'Profile updated.' : 'Could not save changes. Try again.',
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.teal600),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.teal600),
              title: const Text('Choose from library'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final XFile? picked;
    try {
      picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.red700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Text(
            source == ImageSource.camera
                ? 'Camera unavailable. On the simulator, use "Choose from library".'
                : 'Could not open the photo library.',
          ),
        ),
      );
      return;
    }
    if (picked == null || !mounted) return;

    final ok = await ref
        .read(currentUserControllerProvider.notifier)
        .uploadAvatar(picked.path);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? AppColors.green700 : AppColors.red700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        content: Text(ok
            ? 'Profile picture updated.'
            : 'Could not upload picture. Try again.'),
      ),
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.teal600,
            onPrimary: Colors.white,
            onSurface: AppColors.navy900,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(currentUserControllerProvider);
    final user = state.user;

    // Seed once when data first arrives.
    if (user != null && !_seeded) _seedControllers();

    return Scaffold(
      backgroundColor: AppColors.bgCream,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top bar ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.navy900),
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/home'),
                  ),
                  Expanded(
                    child: Text(
                      'Personal Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy900,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _editing = !_editing;
                      if (_editing) _seedControllers();
                    }),
                    child: Text(
                      _editing ? 'Done' : 'Edit',
                      style: TextStyle(
                        color: AppColors.teal600,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (user == null)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ─── Avatar + name ───────────────
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: AppColors.navy900,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.teal500,
                                  width: 3,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              alignment: Alignment.center,
                              child: (user.avatarUrl != null &&
                                      user.avatarUrl!.isNotEmpty)
                                  ? CachedNetworkImage(
                                      imageUrl: user.avatarUrl!,
                                      width: 96,
                                      height: 96,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) =>
                                          const Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => Text(
                                        user.initials,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 30,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      user.initials,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 30,
                                      ),
                                    ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: _pickAndUploadAvatar,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: AppColors.teal500,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.bgCream,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.fullName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PATIENT ID: ${user.patientId ?? _shortId(user.id)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ─── Personal details ────────────
                      _SectionHeader(
                        icon: Icons.person_outline,
                        label: 'Personal Details',
                      ),
                      const SizedBox(height: 10),
                      _Card(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _Field(
                                    label: 'First name',
                                    controller: _firstNameCtrl,
                                    enabled: _editing,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _Field(
                                    label: 'Last name',
                                    controller: _lastNameCtrl,
                                    enabled: _editing,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _DobField(
                                    value: _dob,
                                    enabled: _editing,
                                    onTap: _editing ? _pickDob : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _GenderField(
                                    value: _gender,
                                    enabled: _editing,
                                    onChanged: (v) =>
                                        setState(() => _gender = v),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ─── Contact info ────────────────
                      _SectionHeader(
                        icon: Icons.mail_outline,
                        label: 'Contact Information',
                      ),
                      const SizedBox(height: 10),
                      _Card(
                        child: Column(
                          children: [
                            _ReadOnlyField(
                              label: 'Email address',
                              value: user.email,
                            ),
                            const SizedBox(height: 16),
                            _Field(
                              label: 'Phone number',
                              controller: _phoneCtrl,
                              enabled: _editing,
                              keyboardType: TextInputType.phone,
                              hint: '+1 555-0123',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ─── Address ─────────────────────
                      _SectionHeader(
                        icon: Icons.location_on_outlined,
                        label: 'Residential Address',
                      ),
                      const SizedBox(height: 10),
                      _Card(
                        child: Column(
                          children: [
                            _Field(
                              label: 'Street address',
                              controller: _streetCtrl,
                              enabled: _editing,
                              hint: '123 Main St',
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _Field(
                                    label: 'City',
                                    controller: _cityCtrl,
                                    enabled: _editing,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _Field(
                                    label: 'Zip code',
                                    controller: _zipCtrl,
                                    enabled: _editing,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      if (_editing) ...[
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.teal500,
                              disabledBackgroundColor:
                                  AppColors.teal500.withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.save_outlined,
                                          color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Save Changes',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => setState(() {
                                      _editing = false;
                                      _seedControllers();
                                    }),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: AppColors.border,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _shortId(String id) {
    final clean = id.replaceAll('-', '');
    if (clean.length <= 5) return clean.toUpperCase();
    return 'DS-${clean.substring(0, 5).toUpperCase()}';
  }
}

// ─────────────────────────────────────────────────────────────────
// Building blocks
// ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.teal600),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.teal700,
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.textSubtle,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.enabled,
    this.keyboardType,
    this.hint,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: enabled ? AppColors.navy900 : AppColors.teal700,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            contentPadding: EdgeInsets.symmetric(
              horizontal: enabled ? 12 : 0,
              vertical: enabled ? 10 : 4,
            ),
            filled: enabled,
            fillColor: AppColors.bgCream,
            border: enabled
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  )
                : InputBorder.none,
            enabledBorder: enabled
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  )
                : InputBorder.none,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppColors.teal500, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.teal700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DobField extends StatelessWidget {
  const _DobField({
    required this.value,
    required this.enabled,
    required this.onTap,
  });
  final DateTime? value;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = value == null
        ? '—'
        : '${_month(value!.month)} ${value!.day}, ${value!.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Date of birth'),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: enabled ? 12 : 0,
              vertical: enabled ? 10 : 4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color:
                          enabled ? AppColors.navy900 : AppColors.teal700,
                    ),
                  ),
                ),
                if (enabled)
                  const Icon(Icons.calendar_today_outlined,
                      size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _month(int m) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[(m - 1).clamp(0, 11)];
  }
}

class _GenderField extends StatelessWidget {
  const _GenderField({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });
  final String? value;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  static const _options = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Gender'),
        const SizedBox(height: 6),
        if (!enabled)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              value ?? '—',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.teal700,
              ),
            ),
          )
        else
          DropdownButtonFormField<String>(
            value: _options.contains(value) ? value : null,
            isDense: true,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down,
                color: AppColors.textMuted),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppColors.bgCream,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.navy900,
            ),
            items: _options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: onChanged,
          ),
      ],
    );
  }
}
