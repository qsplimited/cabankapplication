import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Import Theme constants
import 'package:cabankapplication/theme/app_dimensions.dart';
import 'package:cabankapplication/theme/app_colors.dart';
// Assuming AppTheme is defined externally but including it here for the main() function
import 'package:cabankapplication/theme/app_theme.dart';


// --- MOCK DATA STRUCTURES AND SERVICE (For runnability) ---
// These classes usually reside in 'api/profile_mock_data.dart'
class KycDetails {
  final String aadhaarNumber;
  final String panNumber;

  KycDetails({required this.aadhaarNumber, required this.panNumber});
}

class ProfileData {
  final String fullName;
  final String cifId;
  final String mobileNumber;
  final String dateOfBirth;
  DateTime lastLoginTimestamp;
  String emailId;
  String communicationAddress;
  final KycDetails kycDetails;

  ProfileData({
    required this.fullName,
    required this.cifId,
    required this.mobileNumber,
    required this.dateOfBirth,
    required this.lastLoginTimestamp,
    required this.emailId,
    required this.communicationAddress,
    required this.kycDetails,
  });
}

class ProfileService {
  Future<ProfileData> fetchProfileData() async {
    // Simulate network delay and fetch data
    await Future.delayed(const Duration(milliseconds: 800));
    return ProfileData(
      fullName: 'Alex J. Chen',
      cifId: '10987654',
      mobileNumber: '+91 98765 43210',
      dateOfBirth: '15 Jan 1990',
      lastLoginTimestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      emailId: 'alex.chen@example.com',
      communicationAddress: 'Apartment 120, Tech Park Residences, Silicon Valley Road, Bangalore - 560001',
      kycDetails: KycDetails(
        aadhaarNumber: 'XXXX XXXX 1234',
        panNumber: 'ABCDE1234F',
      ),
    );
  }
}
// --- END MOCK DATA ---

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  State<ProfileManagementScreen> createState() => _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> with SingleTickerProviderStateMixin {

  static const int _tabCount = 2; // Personal and KYC
  late TabController _tabController;

  // Data State
  late Future<ProfileData> _profileFuture;
  ProfileData? _currentProfile;
  final ProfileService _profileService = ProfileService(); // Instantiate the service

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);


    _profileFuture = _profileService.fetchProfileData();

    _profileFuture.then((data) {
      if (mounted) {
        setState(() {
          _currentProfile = data;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- DATA UPDATE (Local State Only) ---

  void _updateProfileField(String field, String value) {
    if (_currentProfile == null) return;

    final colorScheme = Theme.of(context).colorScheme;

    setState(() {
      // Logic relies on ProfileData being mutable for these fields
      if (field == 'emailId') {
        _currentProfile!.emailId = value;
      } else if (field == 'communicationAddress') {
        _currentProfile!.communicationAddress = value;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$field updated successfully in local state!'),
          backgroundColor: kSuccessGreen,
        ),
      );
    });
  }

  Future<void> _showEditDialog(String title, String fieldKey, String initialValue) async {
    TextEditingController controller = TextEditingController(text: initialValue);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $title', style: textTheme.titleMedium),
          content: TextField(
            controller: controller,
            keyboardType: fieldKey == 'emailId' ? TextInputType.emailAddress : TextInputType.multiline,
            maxLines: fieldKey == 'communicationAddress' ? 3 : 1,
            decoration: const InputDecoration(hintText: 'Enter new value'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurface)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(
                  'Save',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary, // Use primary color for main action
                  )
              ),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  _updateProfileField(fieldKey, controller.text);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailTile({
    required String label,
    required String value,
    Widget? actionButton,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      // Spacing from constants
      padding: const EdgeInsets.symmetric(vertical: kPaddingSmall + kPaddingExtraSmall), // 12.0
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  // Using bodySmall for label with secondary text color
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: kPaddingExtraSmall), // 4.0
                Text(
                  value,
                  // Using titleMedium for value for prominence
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onBackground,
                  ),
                ),
              ],
            ),
          ),
          if (actionButton != null) actionButton,
        ],
      ),
    );
  }

  // --- TAB VIEWS ---

  Widget _buildPersonalDetailsTab(ProfileData profile) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final editButton = (String title, String fieldKey, String value) => TextButton(
      onPressed: () => _showEditDialog(title, fieldKey, value),
      child: Text(
          'EDIT',
          style: textTheme.labelLarge?.copyWith(
              color: colorScheme.secondary, // Use secondary for action/link text
              fontWeight: FontWeight.bold
          )
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(kPaddingMedium), // 16.0
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailTile(
            label: 'Email ID',
            value: profile.emailId,
            actionButton: editButton('Email ID', 'emailId', profile.emailId),
          ),
          Divider(color: colorScheme.onBackground.withOpacity(0.1)), // Subtle divider

          _buildDetailTile(
            label: 'Registered Mobile Number',
            value: profile.mobileNumber,
          ),
          Divider(color: colorScheme.onBackground.withOpacity(0.1)),

          _buildDetailTile(
            label: 'Date of Birth',
            value: profile.dateOfBirth,
          ),
          Divider(color: colorScheme.onBackground.withOpacity(0.1)),

          _buildDetailTile(
            label: 'Communication Address',
            value: profile.communicationAddress,
            actionButton: editButton('Address', 'communicationAddress', profile.communicationAddress),
          ),
        ],
      ),
    );
  }

  Widget _buildKycTab(ProfileData profile) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(kPaddingMedium), // 16.0
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailTile(
            label: 'Aadhaar Number',
            value: profile.kycDetails.aadhaarNumber,
          ),
          Divider(color: colorScheme.onBackground.withOpacity(0.1)),

          _buildDetailTile(
            label: 'PAN Number',
            value: profile.kycDetails.panNumber,
          ),
          Divider(color: colorScheme.onBackground.withOpacity(0.1)),

          const SizedBox(height: kPaddingMedium), // 16.0
          Text(
            'KYC Status: Verified',
            // Use success color and bodyLarge for prominence
            style: textTheme.bodyLarge?.copyWith(
                color: kSuccessGreen,
                fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: kPaddingSmall), // 8.0
          Text(
            'These details are sourced from official government records and cannot be edited directly.',
            // Use bodySmall for small legal/disclaimer text
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onBackground.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  // --- MAIN BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        // Use primary color for AppBar
        backgroundColor: colorScheme.primary,
        elevation: 1,
        leading: IconButton(
          // Use onPrimary color for icon on primary AppBar
          icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
            'Profile Management',
            // Use titleLarge style and onPrimary color for text
            style: textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary)
        ),
      ),
      body: FutureBuilder<ProfileData>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done || _currentProfile == null) {
            return Center(
              child: CircularProgressIndicator(
                // Use secondary color for loader
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
                child: Text(
                    'Error loading profile: ${snapshot.error}',
                    // Use error color for error message
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.error)
                )
            );
          }

          final profile = _currentProfile!;
          final firstLetter = profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : '?';
          final formattedLastLogin = DateFormat('dd MMM yyyy, hh:mm a').format(profile.lastLoginTimestamp);

          return Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                // Padding from constants
                padding: const EdgeInsets.symmetric(vertical: kPaddingExtraLarge, horizontal: kPaddingMedium),
                // Use surface color for the header background
                color: colorScheme.surface,
                child: Column(
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        // Avatar color uses secondary color
                        color: colorScheme.secondary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          // Shadow color uses onBackground with low opacity
                          BoxShadow(color: colorScheme.onBackground.withOpacity(0.1), blurRadius: kCardElevation, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Center(
                        child: Text(
                          firstLetter,
                          // Use headlineMedium and onPrimary (text on the secondary color surface)
                          style: textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onPrimary,
                            fontSize: 40, // Keeping 40 for visual impact
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: kPaddingSmall + kPaddingExtraSmall), // 12.0
                    Text(
                      profile.fullName,
                      // Use headlineSmall for name
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: kPaddingSmall), // 8.0
                    Text(
                      'CIF ID: ${profile.cifId}',
                      // Use bodyMedium for secondary info
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: kPaddingExtraSmall), // 4.0
                    Text(
                      'Last Login: $formattedLastLogin',
                      // Use secondary color for accent information
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),


              Container(
                color: colorScheme.surface,
                child: TabBar(
                  controller: _tabController,
                  // Use secondary color for tab interaction
                  indicatorColor: colorScheme.secondary,
                  labelColor: colorScheme.secondary,
                  // Use a slightly opaque onSurface color for unselected tabs
                  unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
                  indicatorWeight: 3.0,
                  labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Personal'),
                    Tab(text: 'KYC'),
                  ],
                ),
              ),
              Divider(height: 1, color: colorScheme.onBackground.withOpacity(0.1)), // Subtle divider

              // Tab View Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPersonalDetailsTab(profile),
                    _buildKycTab(profile),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Ensure the main entry point uses the central theme
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bank Profile',
      // Using AppTheme for consistent theme setup
      theme: AppTheme.lightTheme,
      home: const ProfileManagementScreen(),
    );
  }
}