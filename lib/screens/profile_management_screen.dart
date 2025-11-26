// File: lib/screens/profile_screen.dart

import 'package:flutter/material.dart';

// --- MOCK DATA STRUCTURES FOR SELF-CONTAINMENT ---

class NomineeDetails {
  final String name;
  final String relationship;
  final double sharePercentage;
  NomineeDetails({required this.name, required this.relationship, required this.sharePercentage});
}

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
  String emailId; // Made mutable for local state updates
  String communicationAddress; // Made mutable for local state updates
  final KycDetails kycDetails;
  final List<NomineeDetails> nominees;

  ProfileData({
    required this.fullName,
    required this.cifId,
    required this.mobileNumber,
    required this.dateOfBirth,
    required this.emailId,
    required this.communicationAddress,
    required this.kycDetails,
    required this.nominees,
  });
}

// Mock Profile Service (Simulating an API Call)
class ProfileService {
  Future<ProfileData> fetchProfileData() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 700));

    // Static mock data
    return ProfileData(
      fullName: 'Aarav Sharma',
      cifId: 'CIF10023456',
      mobileNumber: '+91 98765 43210',
      dateOfBirth: '20/05/1990',
      emailId: 'aarav.sharma@example.com',
      communicationAddress: 'Plot No. 12, Sector 15, Dwarka, New Delhi - 110078, India',
      kycDetails: KycDetails(
        aadhaarNumber: 'XXXX XXXX 1234',
        panNumber: 'ABCDE1234F',
      ),
      nominees: [
        NomineeDetails(name: 'Priya Sharma', relationship: 'Spouse', sharePercentage: 70),
        NomineeDetails(name: 'Ravi Sharma', relationship: 'Father', sharePercentage: 30),
      ],
    );
  }
}

// --- UI COMPONENTS ---

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  State<ProfileManagementScreen> createState() => _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data State using FutureBuilder
  late Future<ProfileData> _profileFuture;

  // Local state to hold the profile data once loaded
  ProfileData? _currentProfile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Start fetching mock data
    _profileFuture = ProfileService().fetchProfileData();

    // Set up a listener to update local state once the future completes
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
      if (field == 'emailId') {
        _currentProfile!.emailId = value;
      } else if (field == 'communicationAddress') {
        _currentProfile!.communicationAddress = value;
      }

      // Show snackbar confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$field updated successfully in local state!'), backgroundColor: Colors.green),
      );
    });
  }

  // --- UI COMPONENTS ---

  // Dialog to handle editing of Email or Address
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

  // Common tile for displaying profile information
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
          // Email ID (with Edit option)
          _buildDetailTile(
            label: 'Email ID',
            value: profile.emailId,
            actionButton: editButton('Email ID', 'emailId', profile.emailId),
          ),
          Divider(color: Colors.grey[200]),

          // Registered Mobile Number (one number only, no edit)
          _buildDetailTile(
            label: 'Registered Mobile Number',
            value: profile.mobileNumber,
          ),
          Divider(color: Colors.grey[200]),

          // Date of Birth
          _buildDetailTile(
            label: 'Date of Birth',
            value: profile.dateOfBirth,
          ),
          Divider(color: Colors.grey[200]),

          // Communication Address (with Edit option)
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
          // Aadhaar Number (No Edit)
          _buildDetailTile(
            label: 'Aadhaar Number',
            value: profile.kycDetails.aadhaarNumber,
          ),
          Divider(color: Colors.grey[200]),

          // PAN Number (No Edit)
          _buildDetailTile(
            label: 'PAN Number',
            value: profile.kycDetails.panNumber,
          ),
          Divider(color: Colors.grey[200]),

          const SizedBox(height: 20),
          // Placeholder for KYC Status
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

  Widget _buildNomineeTab(ProfileData profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (profile.nominees.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Text(
                  'No nominees currently registered.',
                  style: TextStyle(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          ...profile.nominees.map((nominee) => Card(
            color: Colors.white,
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.group_add_outlined, color: Colors.blue),
              title: Text(nominee.name, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              subtitle: Text(
                'Relationship: ${nominee.relationship}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              trailing: Chip(
                label: Text('${nominee.sharePercentage.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                backgroundColor: Colors.blue,
              ),
            ),
          )),
          // No "Add / Manage Nominees" button, as requested.
        ],
      ),
    );
  }

  // --- MAIN BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Very light background for content
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A2B59), // Dark blue AppBar color
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

          final profile = _currentProfile!; // Use local state for updates
          // Logic for first letter avatar
          final firstLetter = profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : '?';

          return Column(
            children: [
              // Header Section (White background)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
                color: Colors.white,
                child: Column(
                  children: [
                    // Profile Avatar with First Letter
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
                    // User Name
                    Text(
                      profile.fullName,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Customer ID (CIF) only
                    Text(
                      'CIF ID: ${profile.cifId}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Tabs Section (White background)
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
                    Tab(text: 'Nominees'),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey[200]),

              // Tab View Content (Slightly off-white/light gray from Scaffold)
              Expanded( // FIX: Removed 'const' and static access to properly call instance methods
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPersonalDetailsTab(profile),
                    _buildKycTab(profile),
                    _buildNomineeTab(profile),
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

// Main entry point for the application
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
        brightness: Brightness.light, // Explicitly set to light theme
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: const ProfileManagementScreen(),
    );
  }
}