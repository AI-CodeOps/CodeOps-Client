/// Dialog for registering a new API route.
///
/// Provides form fields for all [CreateRouteRequest] properties,
/// with debounced real-time collision check on the route prefix.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/registry_models.dart';
import '../../providers/registry_providers.dart';
import '../../services/cloud/registry_api.dart';
import '../../theme/colors.dart';

/// Dialog for registering a new API route prefix.
///
/// As the user types a routePrefix, a debounced call to
/// [RegistryApi.checkRouteAvailability] provides real-time
/// collision feedback (green check or red warning).
class RouteFormDialog extends ConsumerStatefulWidget {
  /// Available services for the dropdown.
  final List<ServiceRegistrationResponse> services;

  /// Creates a [RouteFormDialog].
  const RouteFormDialog({super.key, required this.services});

  @override
  ConsumerState<RouteFormDialog> createState() => _RouteFormDialogState();
}

class _RouteFormDialogState extends ConsumerState<RouteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _serviceId;
  String? _gatewayServiceId;
  final _prefixCtrl = TextEditingController();
  final _environmentCtrl = TextEditingController();
  final _methodsCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  bool _submitting = false;

  // Collision check state
  Timer? _checkTimer;
  bool? _available;
  bool _checking = false;

  @override
  void dispose() {
    _checkTimer?.cancel();
    _prefixCtrl.dispose();
    _environmentCtrl.dispose();
    _methodsCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _onPrefixChanged(String value) {
    _checkTimer?.cancel();
    setState(() {
      _available = null;
      _checking = false;
    });
    if (value.isEmpty || _environmentCtrl.text.isEmpty) return;
    _checkTimer = Timer(const Duration(milliseconds: 500), _checkCollision);
  }

  void _onEnvironmentChanged(String value) {
    _checkTimer?.cancel();
    setState(() {
      _available = null;
      _checking = false;
    });
    if (value.isEmpty || _prefixCtrl.text.isEmpty) return;
    _checkTimer = Timer(const Duration(milliseconds: 500), _checkCollision);
  }

  Future<void> _checkCollision() async {
    if (_serviceId == null ||
        _prefixCtrl.text.isEmpty ||
        _environmentCtrl.text.isEmpty) {
      return;
    }
    setState(() => _checking = true);
    try {
      final api = ref.read(registryApiProvider);
      final result = await api.checkRouteAvailability(
        gatewayServiceId: _serviceId!,
        environment: _environmentCtrl.text,
        routePrefix: _prefixCtrl.text,
      );
      if (mounted) {
        setState(() {
          _available = result.available;
          _checking = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final api = ref.read(registryApiProvider);
      await api.createRoute(
        serviceId: _serviceId!,
        routePrefix: _prefixCtrl.text,
        environment: _environmentCtrl.text,
        gatewayServiceId: _gatewayServiceId,
        httpMethods:
            _methodsCtrl.text.isEmpty ? null : _methodsCtrl.text,
        description:
            _descriptionCtrl.text.isEmpty ? null : _descriptionCtrl.text,
      );
      ref.invalidate(registryAllRoutesProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CodeOpsColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Register API Route',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CodeOpsColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Service
                  const _FieldLabel('Service *'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _serviceId,
                    decoration: _inputDecoration(),
                    dropdownColor: CodeOpsColors.surface,
                    style: const TextStyle(
                      fontSize: 14,
                      color: CodeOpsColors.textPrimary,
                    ),
                    items: widget.services
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ))
                        .toList(),
                    validator: (v) =>
                        v == null ? 'Service is required' : null,
                    onChanged: (v) => setState(() => _serviceId = v),
                  ),
                  const SizedBox(height: 16),

                  // Route Prefix
                  const _FieldLabel('Route Prefix *'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _prefixCtrl,
                    decoration: _inputDecoration(
                      hint: '/api/v1/resource',
                    ).copyWith(
                      suffixIcon: _buildAvailabilityIndicator(),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                      color: CodeOpsColors.textPrimary,
                    ),
                    maxLength: 200,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Prefix is required' : null,
                    onChanged: _onPrefixChanged,
                  ),
                  const SizedBox(height: 16),

                  // Environment
                  const _FieldLabel('Environment *'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _environmentCtrl,
                    decoration: _inputDecoration(hint: 'e.g., dev'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: CodeOpsColors.textPrimary,
                    ),
                    maxLength: 50,
                    validator: (v) => v == null || v.isEmpty
                        ? 'Environment is required'
                        : null,
                    onChanged: _onEnvironmentChanged,
                  ),
                  const SizedBox(height: 16),

                  // HTTP Methods
                  const _FieldLabel('HTTP Methods'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _methodsCtrl,
                    decoration:
                        _inputDecoration(hint: 'GET,POST,PUT,DELETE'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: CodeOpsColors.textPrimary,
                    ),
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),

                  // Gateway Service
                  const _FieldLabel('Gateway Service'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _gatewayServiceId,
                    decoration: _inputDecoration(),
                    dropdownColor: CodeOpsColors.surface,
                    style: const TextStyle(
                      fontSize: 14,
                      color: CodeOpsColors.textPrimary,
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('None'),
                      ),
                      ...widget.services.map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          )),
                    ],
                    onChanged: (v) =>
                        setState(() => _gatewayServiceId = v),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const _FieldLabel('Description'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descriptionCtrl,
                    decoration: _inputDecoration(hint: 'Optional description'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: CodeOpsColors.textPrimary,
                    ),
                    maxLines: 2,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            _submitting ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: CodeOpsColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Register'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildAvailabilityIndicator() {
    if (_checking) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_available == true) {
      return const Icon(Icons.check_circle, color: CodeOpsColors.success);
    }
    if (_available == false) {
      return const Tooltip(
        message: 'Route prefix collision detected',
        child: Icon(Icons.error, color: CodeOpsColors.warning),
      );
    }
    return null;
  }

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: CodeOpsColors.surfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: CodeOpsColors.primary),
        ),
        counterStyle: const TextStyle(
          fontSize: 10,
          color: CodeOpsColors.textTertiary,
        ),
      );
}

/// Reusable field label.
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: CodeOpsColors.textSecondary,
      ),
    );
  }
}
