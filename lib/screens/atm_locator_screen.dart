// File: lib/screens/atm_locator_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../models/location_model.dart';
import '../api/location_service.dart';

class AtmLocatorScreen extends StatefulWidget {
  const AtmLocatorScreen({super.key});
  static const routeName = '/atm-locator';

  @override
  State<AtmLocatorScreen> createState() => _AtmLocatorScreenState();
}

class _AtmLocatorScreenState extends State<AtmLocatorScreen> {
  final LocationService _locationService = LocationService();

  // State variables
  List<LocationModel> _locations = [];
  bool _isLoading = true;
  String _selectedTypeFilter = 'All';
  Set<String> _currentServiceFilters = {};
  double _currentDistanceRadius = 5.0; // Default search radius in km

  // Master list of services for the advanced filter modal
  final List<String> _availableServices = [
    '24/7',
    'Cash Deposit',
    'Cardless Withdrawal',
    'Wheelchair Access',
    'Forex Services',
    'Locker Facility',
    'Advisory',
    'CDM',
  ];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  // Function to call the service layer and apply all current filters
  void _loadLocations({String? type, List<String>? services, double? radius}) async {
    setState(() {
      _isLoading = true;
      // Update state with new parameters if provided
      _selectedTypeFilter = type ?? _selectedTypeFilter;
      _currentServiceFilters = services != null ? Set.from(services) : _currentServiceFilters;
      _currentDistanceRadius = radius ?? _currentDistanceRadius;
      _locations = [];
    });

    // Call the Mock API service with all current filter criteria
    final results = await _locationService.fetchNearbyLocations(
      userLat: 12.9716,
      userLong: 77.5946,
      typeFilter: _selectedTypeFilter,

      // 🌟 FIX APPLIED HERE: Pass a non-nullable List<String> to the Service.
      serviceFilters: _currentServiceFilters.toList(),
      maxDistanceKm: _currentDistanceRadius,
    );

    setState(() {
      _locations = results;
      _isLoading = false;
    });
  }

  // --- Utility Methods for UI ---

  IconData _getIconForType(String type) {
    switch (type) {
      case 'ATM':
        return Icons.credit_card;
      case 'Branch':
        return Icons.business;
      case 'CDM':
        return Icons.attach_money;
      default:
        return Icons.pin_drop;
    }
  }

  Color _getIconBackgroundColor(String type) {
    switch (type) {
      case 'Branch':
        return kBrandNavy.withOpacity(0.1);
      case 'ATM':
      case 'CDM':
        return kAccentCyan.withOpacity(0.1);
      default:
        return kLightDivider;
    }
  }

  Color _getIconForegroundColor(String type) {
    switch (type) {
      case 'Branch':
        return kBrandNavy;
      case 'ATM':
      case 'CDM':
        return kAccentCyan;
      default:
        return kLightTextPrimary;
    }
  }

  // --- ADVANCED FILTER MODAL ---

  void _showAdvancedFilterModal(BuildContext context) {
    // Local state for the modal until user confirms
    Set<String> tempSelectedServices = Set.from(_currentServiceFilters);
    double tempRadius = _currentDistanceRadius;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusLarge)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final theme = Theme.of(context);
            final textTheme = theme.textTheme;

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.fromLTRB(kPaddingLarge, kPaddingLarge, kPaddingLarge, MediaQuery.of(context).viewInsets.bottom + kPaddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header and Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Advanced Filters', style: textTheme.headlineMedium),
                      IconButton(
                        icon: const Icon(Icons.close, size: kIconSizeLarge),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: kPaddingMedium),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: kPaddingMedium),

                          // Distance Radius Filter
                          Text('Search Radius', style: textTheme.titleMedium),
                          const SizedBox(height: kPaddingSmall),
                          Text(
                            '${tempRadius.toStringAsFixed(1)} km',
                            style: textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
                          ),
                          Slider(
                            value: tempRadius,
                            min: 1.0,
                            max: 20.0,
                            divisions: 19,
                            label: '${tempRadius.toStringAsFixed(1)} km',
                            onChanged: (double value) {
                              setModalState(() {
                                tempRadius = value;
                              });
                            },
                          ),
                          const SizedBox(height: kPaddingLarge),

                          // Service Filters
                          Text('Available Services', style: textTheme.titleMedium),
                          const SizedBox(height: kPaddingSmall),
                          Wrap(
                            spacing: kPaddingSmall,
                            runSpacing: kPaddingSmall,
                            children: _availableServices.map((service) {
                              final isSelected = tempSelectedServices.contains(service);
                              return ChoiceChip(
                                label: Text(service),
                                selected: isSelected,
                                selectedColor: theme.colorScheme.primary,
                                labelStyle: textTheme.bodyMedium?.copyWith(
                                  color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                                ),
                                onSelected: (selected) {
                                  setModalState(() {
                                    if (selected) {
                                      tempSelectedServices.add(service);
                                    } else {
                                      tempSelectedServices.remove(service);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // APPLY Button
                  SizedBox(
                    width: double.infinity,
                    height: kButtonHeight,
                    child: ElevatedButton(
                      onPressed: () {
                        // Trigger data reload with ALL filter criteria
                        _loadLocations(
                          services: tempSelectedServices.toList(),
                          radius: tempRadius,
                        );
                        Navigator.pop(context); // Close modal
                      },
                      child: Text(
                          'APPLY FILTERS (${tempSelectedServices.length})',
                          style: textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary)
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- BUILD METHODS (UI Layout) ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // APP BAR with Filter Icon
      appBar: AppBar(
        title: const Text('Find ATM / Branch'),
        backgroundColor: kAccentOrange,
        elevation: 0,
        centerTitle: false,
        actions: [
          // The Advanced Filter Icon (Right Corner)
          IconButton(
            icon: Icon(Icons.filter_list, color: theme.colorScheme.onSurface),
            onPressed: () => _showAdvancedFilterModal(context),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Filter Chips
          Padding(
            padding: const EdgeInsets.only(
              top: kPaddingSmall,
              left: kPaddingMedium,
              right: kPaddingMedium,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildFilterChip(context, 'All', primaryColor),
                  _buildFilterChip(context, 'ATM', primaryColor),
                  _buildFilterChip(context, 'Branch', primaryColor),
                  _buildFilterChip(context, 'CDM', primaryColor),
                ],
              ),
            ),
          ),

          // Filter Summary Banner
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: kPaddingMedium,
              horizontal: kPaddingMedium,
            ),
            child: Text(
              _isLoading
                  ? 'Searching nearby locations...'
                  : 'Showing ${_locations.length} ${_selectedTypeFilter.toLowerCase()} within ${_currentDistanceRadius.toStringAsFixed(1)} km.',
              style: textTheme.titleSmall?.copyWith(
                color: kLightTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Location List (The Results)
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : _locations.isEmpty
                ? Center(
              child: Text(
                'No ${_selectedTypeFilter} found with current filters.',
                style: textTheme.titleMedium,
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: kPaddingMedium),
              itemCount: _locations.length,
              itemBuilder: (context, index) {
                final location = _locations[index];
                return _buildLocationListItem(context, location);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, Color primaryColor) {
    final bool isSelected = _selectedTypeFilter == label;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: kPaddingSmall),
      child: ChoiceChip(
        label: Text(label),
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          color: isSelected ? theme.colorScheme.onPrimary : kLightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        selected: isSelected,
        selectedColor: primaryColor,
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusSmall),
          side: BorderSide(
            color: isSelected ? primaryColor : kLightDivider,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        onSelected: (selected) {
          if (selected) {
            // Only update the type filter, keeping the service/radius filters
            _loadLocations(type: label);
          }
        },
      ),
    );
  }

  Widget _buildLocationListItem(BuildContext context, LocationModel location) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final statusColor = location.isOpen ? kSuccessGreen : kErrorRed;

    return Card(
      elevation: kCardElevation,
      margin: const EdgeInsets.only(bottom: kPaddingMedium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusMedium),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(kPaddingMedium),

        // LEADING ICON
        leading: Container(
          width: kTxnLeadingSize,
          height: kTxnLeadingSize,
          decoration: BoxDecoration(
            color: _getIconBackgroundColor(location.type),
            borderRadius: BorderRadius.circular(kRadiusSmall),
          ),
          alignment: Alignment.center,
          child: Icon(
            _getIconForType(location.type),
            color: _getIconForegroundColor(location.type),
            size: kIconSize,
          ),
        ),

        // TITLE & SUBTITLE
        title: Padding(
          padding: const EdgeInsets.only(bottom: kPaddingExtraSmall),
          child: Text(
            location.name,
            style: textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address
            Text(
              location.address,
              style: textTheme.bodyMedium?.copyWith(color: kLightTextSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: kPaddingSmall),

            // Status and Distance Row
            Row(
              children: [
                // Status (Open/Closed)
                Icon(Icons.access_time, size: kIconSizeSmall, color: statusColor),
                const SizedBox(width: kPaddingExtraSmall),
                Text(
                  location.isOpen ? 'Open Now' : 'Closed',
                  style: textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(width: kPaddingMedium),

                // Distance
                Icon(Icons.location_on, size: kIconSizeSmall, color: kAccentOrange),
                const SizedBox(width: kPaddingExtraSmall),
                Text(
                  '${location.distanceKm.toStringAsFixed(1)} km',
                  style: textTheme.labelSmall?.copyWith(
                    color: kAccentOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),

        // TRAILING (Navigation Icon)
        trailing: IconButton(
          icon: Icon(
            Icons.navigation,
            color: theme.colorScheme.primary,
            size: kIconSize,
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Launching navigation to ${location.name}')),
            );
          },
        ),

        onTap: () {
          // TODO: Navigate to the Location Detail screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Viewing details for ${location.name}')),
          );
        },
      ),
    );
  }
}