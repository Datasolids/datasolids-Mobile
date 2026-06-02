// Select Your Health System — searches the re-hosted Epic endpoint directory
// (GET /integrations/epic/organizations/), with infinite scroll. Tapping a
// result starts the real SMART-on-FHIR OAuth flow: the backend returns the
// org's authorize URL, which we open in a secure in-app browser session
// (ASWebAuthenticationSession / Chrome Custom Tab via flutter_web_auth_2).
// The patient signs in on the hospital's own MyChart page; the backend
// callback redirects to datasolids://epic-callback to hand control back here.

import 'dart:async';

import 'package:datasolids_mobile/core/theme/app_colors.dart';
import 'package:datasolids_mobile/features/connect/data/connect_api.dart';
import 'package:datasolids_mobile/features/connect/data/dtos/epic_org.dart';
import 'package:datasolids_mobile/features/connect/presentation/widgets/flow_bottom_nav.dart';
import 'package:datasolids_mobile/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:go_router/go_router.dart';

const _kCallbackScheme = 'datasolids';
const _kPageSize = 25;

class SelectHealthSystemScreen extends ConsumerStatefulWidget {
  const SelectHealthSystemScreen({super.key});

  @override
  ConsumerState<SelectHealthSystemScreen> createState() =>
      _SelectHealthSystemScreenState();
}

class _SelectHealthSystemScreenState
    extends ConsumerState<SelectHealthSystemScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;
  CancelToken? _cancel;

  List<EpicOrg> _results = const [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  bool _connecting = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetch('', reset: true); // starter list before the user types
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cancel?.cancel();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _query = value.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_query.length == 1) {
        setState(() {
          _results = const [];
          _hasMore = false;
          _error = null;
          _loading = false;
        });
        return;
      }
      _fetch(_query, reset: true);
    });
  }

  void _onScroll() {
    if (_loading || _loadingMore || !_hasMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 320) {
      _fetch(_query, reset: false);
    }
  }

  Future<void> _fetch(String query, {required bool reset}) async {
    _cancel?.cancel();
    final token = CancelToken();
    _cancel = token;
    setState(() {
      if (reset) {
        _loading = true;
        _error = null;
      } else {
        _loadingMore = true;
      }
    });
    try {
      final page = await ref.read(connectApiProvider).searchOrganizations(
            query,
            offset: reset ? 0 : _results.length,
            limit: _kPageSize,
            cancelToken: token,
          );
      if (!mounted || token.isCancelled) return;
      setState(() {
        _results = reset ? page.results : [..._results, ...page.results];
        _hasMore = page.hasMore;
        _loading = false;
        _loadingMore = false;
      });
    } on DioException catch (e) {
      if (CancelToken.isCancel(e) || !mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = 'Could not load health systems. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = 'Could not load health systems. Please try again.';
      });
    }
  }

  Future<void> _onSelect(EpicOrg org) async {
    if (_connecting) return;
    setState(() => _connecting = true);
    try {
      final authorizeUrl =
          await ref.read(connectApiProvider).startOauth(org.id);
      final result = await FlutterWebAuth2.authenticate(
        url: authorizeUrl,
        callbackUrlScheme: _kCallbackScheme,
      );
      if (!mounted) return;
      final status = Uri.parse(result).queryParameters['status'];
      if (status == 'connected') {
        // Refresh the dashboard so the new source shows up, then go home.
        unawaited(ref.read(dashboardControllerProvider.notifier).refresh());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${org.name}. Syncing your records…'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/home');
      } else {
        _showError('Connection was not completed. Please try again.');
      }
    } on PlatformException {
      // User cancelled the in-app browser — no-op.
    } catch (_) {
      _showError("Couldn't start the secure sign-in. Please try again.");
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const FlowBottomNav(activeIndex: 1),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, size: 22),
                      color: AppColors.navy900,
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Your Health System',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Search for your Epic hospital or clinic',
                        style:
                            TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 16),
                      _SearchField(
                          controller: _controller, onChanged: _onChanged),
                      const SizedBox(height: 18),
                      Text(
                        'RESULTS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                          color: AppColors.textSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(child: _buildBody()),
                const SizedBox(height: 8),
                const _EncryptedFooter(),
                const SizedBox(height: 8),
              ],
            ),
          ),
          if (_connecting)
            const _ConnectingOverlay(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _results.isEmpty) {
      return _Message(
        icon: Icons.cloud_off_outlined,
        title: _error!,
        actionLabel: 'Retry',
        onAction: () => _fetch(_query, reset: true),
      );
    }
    if (_query.length == 1) {
      return const _Message(
        icon: Icons.search,
        title: 'Keep typing to search',
        subtitle: 'Enter at least 2 characters.',
      );
    }
    if (_results.isEmpty) {
      return _Message(
        icon: Icons.search_off,
        title: _query.isEmpty
            ? 'Start typing to find your provider'
            : 'No health systems match "$_query"',
      );
    }
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      itemCount: _results.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        if (i >= _results.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return _OrgRow(org: _results[i], onTap: _onSelect);
      },
    );
  }
}

class _ConnectingOverlay extends StatelessWidget {
  const _ConnectingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withOpacity(0.35),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Opening secure sign-in…',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: TextStyle(fontSize: 14, color: AppColors.navy900),
      decoration: InputDecoration(
        hintText: 'Search by hospital or clinic name',
        hintStyle: TextStyle(color: AppColors.textSubtle, fontSize: 14),
        prefixIcon: Icon(Icons.search, color: AppColors.textSubtle, size: 20),
        filled: true,
        fillColor: AppColors.bgCream,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border.withOpacity(0.7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border.withOpacity(0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.teal600, width: 1.4),
        ),
      ),
    );
  }
}

class _OrgRow extends StatelessWidget {
  const _OrgRow({required this.org, required this.onTap});
  final EpicOrg org;
  final ValueChanged<EpicOrg> onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(org),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.teal500.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.local_hospital_outlined,
                  color: AppColors.teal700, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    org.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy900,
                    ),
                  ),
                  if (org.state.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      org.state,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSubtle, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textSubtle),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.navy900,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: TextStyle(
                    color: AppColors.teal600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EncryptedFooter extends StatelessWidget {
  const _EncryptedFooter();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 14, color: AppColors.textSubtle),
        const SizedBox(width: 6),
        Text(
          'END-TO-END ENCRYPTED CONNECTION',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: AppColors.textSubtle,
          ),
        ),
      ],
    );
  }
}
