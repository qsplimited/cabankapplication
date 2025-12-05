// File: lib/screens/nominee_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/nominee_model.dart';
import '../api/nominee_service.dart';
// Assuming these files are in lib/theme/ and are accessible for style constants
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_sizes.dart';

// --- Main Screen ---

class NomineeListScreen extends StatefulWidget {
  final String accountType; // e.g., 'Savings', 'Fixed Deposit'

  const NomineeListScreen({super.key, required this.accountType});

  @override
  State<NomineeListScreen> createState() => _NomineeListScreenState();
}

class _NomineeListScreenState extends State<NomineeListScreen> {
  final NomineeService _nomineeService = NomineeService();
  late Future<List<NomineeModel>> _nomineesFuture;
  List<NomineeModel> _nominees = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchNominees();
  }

  void _fetchNominees() {
    setState(() {
      _nomineesFuture = _nomineeService.fetchNomineesByAccountType(widget.accountType);
      _nomineesFuture.then((data) {
        setState(() {
          _nominees = data;
        });
      }).catchError((error) {
        // Show error message (e.g., using a SnackBar)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching nominees: $error')),
        );
      });
    });
  }

  // --- Handlers ---

  void _handleEdit(NomineeModel nominee) async {
    // Navigate to a dedicated update screen or show a bottom sheet/dialog
    // For this example, we'll use a simple dialog to simulate the update flow.
    final updatedNominee = await showDialog<NomineeModel>(
      context: context,
      builder: (context) => NomineeUpdateDialog(nominee: nominee),
    );

    if (updatedNominee != null) {
      setState(() {
        _isLoading = true;
      });
      try {
        // 1. Call the mock API to update the data
        final result = await _nomineeService.updateNominee(updatedNominee);

        // 2. Update the local state with the result
        final index = _nominees.indexWhere((n) => n.id == result.id);
        if (index != -1) {
          setState(() {
            _nominees[index] = result;
          });
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.fullName} updated successfully!'),
            backgroundColor: kSuccessGreen,
          ),
        );
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            backgroundColor: kErrorRed,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.accountType} Nominee Details'),
        backgroundColor: theme.colorScheme.surface,
        elevation: kCardElevation,
      ),
      body: FutureBuilder<List<NomineeModel>>(
        future: _nomineesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load data: ${snapshot.error}'));
          }
          if (_nominees.isEmpty) {
            return const Center(child: Text('No nominees are registered for this account.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(kPaddingMedium),
            itemCount: _nominees.length,
            itemBuilder: (context, index) {
              final nominee = _nominees[index];
              return NomineeCard(
                nominee: nominee,
                onEdit: _handleEdit,
                theme: theme,
              );
            },
          );
        },
      ),
    );
  }
}

// --- Nominee Card Widget ---

class NomineeCard extends StatelessWidget {
  final NomineeModel nominee;
  final Function(NomineeModel) onEdit;
  final ThemeData theme;

  const NomineeCard({
    super.key,
    required this.nominee,
    required this.onEdit,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: theme.colorScheme.surface,
      elevation: kCardElevation,
      margin: const EdgeInsets.only(bottom: kPaddingSmall),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Name and Edit Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    nominee.fullName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: theme.colorScheme.primary, size: kIconSizeSmall),
                  onPressed: () => onEdit(nominee),
                  tooltip: 'Edit Nominee Details',
                ),
              ],
            ),
            const SizedBox(height: kPaddingSmall),
            const Divider(height: kDividerHeight, color: kLightDivider),
            const SizedBox(height: kPaddingSmall),

            // Details Rows
            _buildDetailRow(
                context,
                'Relationship:',
                nominee.relationship,
                theme
            ),
            _buildDetailRow(
                context,
                'Share:',
                '${nominee.sharePercentage.toStringAsFixed(0)}%',
                theme
            ),
            _buildDetailRow(
                context,
                'Account Type:',
                nominee.accountType,
                theme
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kPaddingExtraSmall),
      child: Row(
        children: [
          SizedBox(
            width: kLabelColumnWidth, // Use fixed width for alignment
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: kLightTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Nominee Update Dialog (Simple Form Simulation) ---

class NomineeUpdateDialog extends StatefulWidget {
  final NomineeModel nominee;

  const NomineeUpdateDialog({super.key, required this.nominee});

  @override
  State<NomineeUpdateDialog> createState() => _NomineeUpdateDialogState();
}

class _NomineeUpdateDialogState extends State<NomineeUpdateDialog> {
  late TextEditingController _nameController;
  late TextEditingController _shareController;
  late String _selectedRelationship;

  final List<String> _relationships = [
    'Spouse',
    'Son',
    'Daughter',
    'Parent',
    'Sibling',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.nominee.fullName);
    _shareController = TextEditingController(text: widget.nominee.sharePercentage.toStringAsFixed(0));
    _selectedRelationship = widget.nominee.relationship;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shareController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    // Basic validation
    final newName = _nameController.text.trim();
    final newShare = double.tryParse(_shareController.text.trim());

    if (newName.isEmpty || newShare == null || newShare < 0 || newShare > 100) {
      // Show error or disable button
      return;
    }

    // Create the updated model
    final updatedNominee = widget.nominee.copyWith(
      fullName: newName,
      relationship: _selectedRelationship,
      sharePercentage: newShare,
    );

    // Return the updated model to the calling screen
    Navigator.of(context).pop(updatedNominee);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Ensure the initial relationship is in the list, or default to 'Other'
    if (!_relationships.contains(_selectedRelationship)) {
      _relationships.insert(0, _selectedRelationship);
    }

    return AlertDialog(
      title: Text('Update Nominee: ${widget.nominee.fullName}', style: theme.textTheme.titleMedium),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            // Nominee Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Legal Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: kPaddingMedium),

            // Relationship Dropdown
            DropdownButtonFormField<String>(
              value: _selectedRelationship,
              decoration: const InputDecoration(
                labelText: 'Relationship',
                prefixIcon: Icon(Icons.family_restroom),
              ),
              items: _relationships.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedRelationship = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: kPaddingMedium),

            // Share Percentage
            TextFormField(
              controller: _shareController,
              decoration: const InputDecoration(
                labelText: 'Share Percentage (0-100)',
                suffixText: '%',
                prefixIcon: Icon(Icons.percent),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Cancel', style: TextStyle(color: kErrorRed)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}

// --- Example Main Widget (for running the file) ---

class MainAppWrapper extends StatelessWidget {
  const MainAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // This wrapper is needed to simulate navigation or state management
    // In a real app, you would pass the current account type (e.g., 'Savings')
    // from a parent screen.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nominee Management',
      theme: Theme.of(context), // Use the provided theme
      home: const NomineeListScreen(accountType: 'Savings'),
    );
  }
}