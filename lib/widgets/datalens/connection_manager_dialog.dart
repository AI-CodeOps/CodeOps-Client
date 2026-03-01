/// Connection Manager dialog for DataLens.
///
/// Split dialog with a connection list (left) and a configuration form (right).
/// Supports creating, editing, deleting, and testing database connections.
/// Includes a color picker for visual identification and full form validation.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/datalens_enums.dart';
import '../../models/datalens_models.dart';
import '../../providers/datalens_providers.dart';
import '../../theme/colors.dart';

/// Predefined connection colors for the color picker.
const List<Color> _connectionColors = [
  Color(0xFF6C63FF), // Purple (primary)
  Color(0xFF3B82F6), // Blue
  Color(0xFF14B8A6), // Teal
  Color(0xFF4ADE80), // Green
  Color(0xFFFBBF24), // Yellow
  Color(0xFFF97316), // Orange
  Color(0xFFEF4444), // Red
  Color(0xFFA855F7), // Violet
  Color(0xFFEC4899), // Pink
  Color(0xFF06B6D4), // Cyan
];

const _uuid = Uuid();

/// Dialog for managing DataLens database connections.
class ConnectionManagerDialog extends ConsumerStatefulWidget {
  /// Creates a [ConnectionManagerDialog].
  const ConnectionManagerDialog({super.key});

  @override
  ConsumerState<ConnectionManagerDialog> createState() =>
      _ConnectionManagerDialogState();
}

class _ConnectionManagerDialogState
    extends ConsumerState<ConnectionManagerDialog> {
  String? _selectedConnectionId;
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final connectionsAsync = ref.watch(datalensConnectionsProvider);

    return Dialog(
      backgroundColor: CodeOpsColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: CodeOpsColors.border),
      ),
      child: SizedBox(
        width: 800,
        height: 520,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: CodeOpsColors.border),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.storage_outlined,
                    size: 20,
                    color: CodeOpsColors.primary,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Connection Manager',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CodeOpsColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: CodeOpsColors.textTertiary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content — split list + form
            Expanded(
              child: Row(
                children: [
                  // Left panel — connection list
                  SizedBox(
                    width: 240,
                    child: _ConnectionList(
                      connectionsAsync: connectionsAsync,
                      selectedId: _selectedConnectionId,
                      onSelect: (id) => setState(() {
                        _selectedConnectionId = id;
                        _isCreating = false;
                      }),
                      onAdd: () => setState(() {
                        _isCreating = true;
                        _selectedConnectionId = null;
                      }),
                      onDelete: _deleteConnection,
                    ),
                  ),
                  Container(width: 1, color: CodeOpsColors.border),

                  // Right panel — form
                  Expanded(
                    child: _isCreating
                        ? _ConnectionForm(
                            key: const ValueKey('new'),
                            onSaved: (conn) {
                              setState(() {
                                _isCreating = false;
                                _selectedConnectionId = conn.id;
                              });
                              ref.invalidate(datalensConnectionsProvider);
                            },
                          )
                        : _selectedConnectionId != null
                            ? _ConnectionForm(
                                key: ValueKey(_selectedConnectionId),
                                connectionId: _selectedConnectionId,
                                onSaved: (_) {
                                  ref.invalidate(datalensConnectionsProvider);
                                },
                              )
                            : const Center(
                                child: Text(
                                  'Select or create a connection',
                                  style: TextStyle(
                                    color: CodeOpsColors.textTertiary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Deletes a connection after confirmation.
  Future<void> _deleteConnection(String connectionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CodeOpsColors.surface,
        title: const Text('Delete Connection'),
        content: const Text('Are you sure you want to delete this connection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: CodeOpsColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = ref.read(datalensConnectionServiceProvider);
      await service.deleteConnection(connectionId);
      ref.invalidate(datalensConnectionsProvider);
      if (mounted) {
        setState(() {
          if (_selectedConnectionId == connectionId) {
            _selectedConnectionId = null;
          }
        });
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Connection List (left panel)
// ---------------------------------------------------------------------------

class _ConnectionList extends StatelessWidget {
  final AsyncValue<List<DatabaseConnection>> connectionsAsync;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<String> onDelete;

  const _ConnectionList({
    required this.connectionsAsync,
    required this.selectedId,
    required this.onSelect,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Add button
        Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: double.infinity,
            height: 32,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Connection', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: CodeOpsColors.primary,
                side: const BorderSide(color: CodeOpsColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: onAdd,
            ),
          ),
        ),
        const Divider(height: 1, color: CodeOpsColors.border),

        // Connection list
        Expanded(
          child: connectionsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: CodeOpsColors.primary,
                strokeWidth: 2,
              ),
            ),
            error: (error, _) => Center(
              child: Text(
                'Error: $error',
                style: const TextStyle(
                  color: CodeOpsColors.error,
                  fontSize: 11,
                ),
              ),
            ),
            data: (connections) {
              if (connections.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No connections yet.\nClick "New Connection" to add one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CodeOpsColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: connections.length,
                itemBuilder: (context, index) {
                  final conn = connections[index];
                  final isSelected = conn.id == selectedId;
                  final color = conn.color != null
                      ? Color(int.parse('FF${conn.color!}', radix: 16))
                      : CodeOpsColors.textTertiary;

                  return InkWell(
                    onTap: () => onSelect(conn.id!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      color: isSelected
                          ? CodeOpsColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  conn.name ?? 'Unnamed',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w500
                                        : FontWeight.w400,
                                    color: CodeOpsColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${conn.host ?? 'localhost'}:${conn.port ?? 5432}/${conn.database ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: CodeOpsColors.textTertiary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16),
                            color: CodeOpsColors.textTertiary,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                            onPressed: () {
                              if (conn.id != null) onDelete(conn.id!);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Connection Form (right panel)
// ---------------------------------------------------------------------------

class _ConnectionForm extends ConsumerStatefulWidget {
  final String? connectionId;
  final ValueChanged<DatabaseConnection> onSaved;

  const _ConnectionForm({
    super.key,
    this.connectionId,
    required this.onSaved,
  });

  @override
  ConsumerState<_ConnectionForm> createState() => _ConnectionFormState();
}

class _ConnectionFormState extends ConsumerState<_ConnectionForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _databaseController;
  late TextEditingController _schemaController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _timeoutController;
  bool _useSsl = false;
  Color _selectedColor = _connectionColors.first;
  bool _isTesting = false;
  bool _isSaving = false;
  String? _testResult;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _hostController = TextEditingController(text: 'localhost');
    _portController = TextEditingController(text: '5432');
    _databaseController = TextEditingController();
    _schemaController = TextEditingController(text: 'public');
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _timeoutController = TextEditingController(text: '10');

    if (widget.connectionId != null) {
      _loadConnection();
    }
  }

  /// Loads existing connection data into the form.
  Future<void> _loadConnection() async {
    final service = ref.read(datalensConnectionServiceProvider);
    final conn = await service.getConnectionById(widget.connectionId!);
    if (conn != null && mounted) {
      setState(() {
        _nameController.text = conn.name ?? '';
        _hostController.text = conn.host ?? 'localhost';
        _portController.text = (conn.port ?? 5432).toString();
        _databaseController.text = conn.database ?? '';
        _schemaController.text = conn.schema ?? 'public';
        _usernameController.text = conn.username ?? '';
        _passwordController.text = conn.password ?? '';
        _timeoutController.text = (conn.connectionTimeout ?? 10).toString();
        _useSsl = conn.useSsl ?? false;
        if (conn.color != null) {
          try {
            _selectedColor =
                Color(int.parse('FF${conn.color!}', radix: 16));
          } catch (_) {
            // Keep default color on parse error.
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _databaseController.dispose();
    _schemaController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _timeoutController.dispose();
    super.dispose();
  }

  /// Builds a [DatabaseConnection] from the current form state.
  DatabaseConnection _buildConfig() {
    final colorHex = _selectedColor
        .toARGB32()
        .toRadixString(16)
        .substring(2)
        .toUpperCase();
    return DatabaseConnection(
      id: widget.connectionId ?? _uuid.v4(),
      name: _nameController.text.trim(),
      driver: DatabaseDriver.postgresql,
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ?? 5432,
      database: _databaseController.text.trim(),
      schema: _schemaController.text.trim().isEmpty
          ? null
          : _schemaController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text.isEmpty
          ? null
          : _passwordController.text,
      useSsl: _useSsl,
      color: colorHex,
      connectionTimeout: int.tryParse(_timeoutController.text.trim()) ?? 10,
    );
  }

  /// Tests the connection using the current form values.
  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
      _testResult = null;
      _testSuccess = null;
    });

    try {
      final service = ref.read(datalensConnectionServiceProvider);
      final result = await service.testConnection(_buildConfig());
      if (mounted) {
        setState(() {
          _testSuccess = result.success;
          _testResult = result.success
              ? 'Connected in ${result.latency.inMilliseconds}ms'
              : 'Failed: ${result.error}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testSuccess = false;
          _testResult = 'Error: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  /// Saves the connection (create or update).
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final service = ref.read(datalensConnectionServiceProvider);
      final config = _buildConfig();
      DatabaseConnection saved;

      if (widget.connectionId != null) {
        saved = await service.updateConnection(config);
      } else {
        saved = await service.saveConnection(config);
      }

      widget.onSaved(saved);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.connectionId != null
                ? 'Connection updated'
                : 'Connection created'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Connection Name
          _FormField(
            label: 'Connection Name',
            child: TextFormField(
              controller: _nameController,
              decoration: _inputDecoration('e.g., CodeOps Dev'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              style: _fieldTextStyle,
            ),
          ),
          const SizedBox(height: 12),

          // Color picker
          _FormField(
            label: 'Color',
            child: Wrap(
              spacing: 6,
              children: _connectionColors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Host + Port row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _FormField(
                  label: 'Host',
                  child: TextFormField(
                    controller: _hostController,
                    decoration: _inputDecoration('localhost'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Host is required'
                        : null,
                    style: _fieldTextStyle,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FormField(
                  label: 'Port',
                  child: TextFormField(
                    controller: _portController,
                    decoration: _inputDecoration('5432'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Required';
                      }
                      final port = int.tryParse(v.trim());
                      if (port == null || port < 1 || port > 65535) {
                        return 'Invalid';
                      }
                      return null;
                    },
                    style: _fieldTextStyle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Database
          _FormField(
            label: 'Database',
            child: TextFormField(
              controller: _databaseController,
              decoration: _inputDecoration('database name'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Database is required'
                  : null,
              style: _fieldTextStyle,
            ),
          ),
          const SizedBox(height: 12),

          // Default Schema
          _FormField(
            label: 'Default Schema',
            child: TextFormField(
              controller: _schemaController,
              decoration: _inputDecoration('public'),
              style: _fieldTextStyle,
            ),
          ),
          const SizedBox(height: 12),

          // Username + Password row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FormField(
                  label: 'Username',
                  child: TextFormField(
                    controller: _usernameController,
                    decoration: _inputDecoration('username'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Username is required'
                        : null,
                    style: _fieldTextStyle,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FormField(
                  label: 'Password',
                  child: TextFormField(
                    controller: _passwordController,
                    decoration: _inputDecoration('password'),
                    obscureText: true,
                    style: _fieldTextStyle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // SSL + Timeout row
          Row(
            children: [
              // SSL toggle
              Expanded(
                child: _FormField(
                  label: 'SSL',
                  child: SwitchListTile(
                    value: _useSsl,
                    onChanged: (v) => setState(() => _useSsl = v),
                    title: Text(
                      _useSsl ? 'Enabled' : 'Disabled',
                      style: _fieldTextStyle,
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: CodeOpsColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Timeout
              SizedBox(
                width: 120,
                child: _FormField(
                  label: 'Timeout (s)',
                  child: TextFormField(
                    controller: _timeoutController,
                    decoration: _inputDecoration('10'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: _fieldTextStyle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Test result banner
          if (_testResult != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: (_testSuccess == true
                        ? CodeOpsColors.success
                        : CodeOpsColors.error)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _testSuccess == true
                      ? CodeOpsColors.success
                      : CodeOpsColors.error,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _testSuccess == true ? Icons.check_circle : Icons.error,
                    size: 16,
                    color: _testSuccess == true
                        ? CodeOpsColors.success
                        : CodeOpsColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _testResult!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _testSuccess == true
                            ? CodeOpsColors.success
                            : CodeOpsColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _isTesting || _isSaving ? null : _testConnection,
                style: OutlinedButton.styleFrom(
                  foregroundColor: CodeOpsColors.secondary,
                  side: const BorderSide(color: CodeOpsColors.secondary),
                ),
                child: _isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CodeOpsColors.secondary,
                        ),
                      )
                    : const Text('Test Connection'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isSaving || _isTesting ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CodeOpsColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(widget.connectionId != null ? 'Update' : 'Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _fieldTextStyle = TextStyle(
    fontSize: 13,
    color: CodeOpsColors.textPrimary,
  );

  static InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: CodeOpsColors.textTertiary,
        fontSize: 13,
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: CodeOpsColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: CodeOpsColors.primary),
        borderRadius: BorderRadius.circular(6),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: CodeOpsColors.error),
        borderRadius: BorderRadius.circular(6),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: CodeOpsColors.error),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form Field Label
// ---------------------------------------------------------------------------

class _FormField extends StatelessWidget {
  final String label;
  final Widget child;

  const _FormField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: CodeOpsColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
