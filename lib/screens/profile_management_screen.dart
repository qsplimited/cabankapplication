
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Import the service file and access the models defined within it
import '../api/profile_mock_data.dart';

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

    setState(() {
      // Logic relies on ProfileData being mutable for these fields
      if (field == 'emailId') {
        _currentProfile!.emailId = value;
      } else if (field == 'communicationAddress') {
        _currentProfile!.communicationAddress = value;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$field updated successfully in local state!'), backgroundColor: Colors.green),
      );
    });
  }

  Future<void> _showEditDialog(String title, String fieldKey, String initialValue) async {
    TextEditingController controller = TextEditingController(text: initialValue);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $title'),
          content: TextField(
            controller: controller,
            keyboardType: fieldKey == 'emailId' ? TextInputType.emailAddress : TextInputType.multiline,
            maxLines: fieldKey == 'communicationAddress' ? 3 : 1,
            decoration: InputDecoration(hintText: 'Enter new $title'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
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
    final editButton = (String title, String fieldKey, String value) => TextButton(
      onPressed: () => _showEditDialog(title, fieldKey, value),
      child: const Text('EDIT', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailTile(
            label: 'Email ID',
            value: profile.emailId,
            actionButton: editButton('Email ID', 'emailId', profile.emailId),
          ),
          Divider(color: Colors.grey[200]),

          _buildDetailTile(
            label: 'Registered Mobile Number',
            value: profile.mobileNumber,
          ),
          Divider(color: Colors.grey[200]),

          _buildDetailTile(
            label: 'Date of Birth',
            value: profile.dateOfBirth,
          ),
          Divider(color: Colors.grey[200]),

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
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailTile(
            label: 'Aadhaar Number',
            value: profile.kycDetails.aadhaarNumber,
          ),
          Divider(color: Colors.grey[200]),

          _buildDetailTile(
            label: 'PAN Number',
            value: profile.kycDetails.panNumber,
          ),
          Divider(color: Colors.grey[200]),

          const SizedBox(height: 20),
          const Text(
            'KYC Status: Verified',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Text(
            'These details are sourced from official government records and cannot be edited directly.',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  // --- MAIN BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A2B59),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile Management', style: TextStyle(color: Colors.white)),
      ),
      body: FutureBuilder<ProfileData>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done || _currentProfile == null) {
            return const Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading profile: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          final profile = _currentProfile!;
          final firstLetter = profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : '?';
          final formattedLastLogin = DateFormat('dd MMM yyyy, hh:mm a').format(profile.lastLoginTimestamp);

          return Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
                color: Colors.white,
                child: Column(
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                        ],
                      ),
                      child: Center(
                        child: Text(
                          firstLetter,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.fullName,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'CIF ID: ${profile.cifId}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last Login: $formattedLastLogin',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),


              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.blue,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  indicatorWeight: 3.0,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Personal'),
                    Tab(text: 'KYC'),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey[200]),

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
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: const ProfileManagementScreen(),
    );
  }
}