import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../providers/profile_provider.dart';
import '../models/profile_model.dart';

class ProfileManagementScreen extends ConsumerStatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  ConsumerState<ProfileManagementScreen> createState() => _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends ConsumerState<ProfileManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kAccentOrange, // Brand color
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kAccentOrange)),
        error: (err, _) => Center(child: Text("Error loading profile")),
        data: (profile) => Column(
          children: [
            _buildHeader(profile),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPersonalTab(profile),
                  _buildKycTab(profile),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ProfileData profile) {
    return Container(
      padding: const EdgeInsets.all(kPaddingLarge),
      color: Colors.white,
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: kAccentOrange,
            child: Text(profile.fullName[0], style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          Text(profile.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text("CIF ID: ${profile.cifId}", style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 5),
          Text("Last Login: ${DateFormat('dd MMM yyyy, hh:mm a').format(profile.lastLoginTimestamp)}",
              style: const TextStyle(color: kAccentOrange, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: kAccentOrange,
        labelColor: kAccentOrange,
        unselectedLabelColor: Colors.grey,
        tabs: const [Tab(text: "PERSONAL"), Tab(text: "KYC")],
      ),
    );
  }

  Widget _buildPersonalTab(ProfileData profile) {
    return ListView(
      padding: const EdgeInsets.all(kPaddingMedium),
      children: [
        _buildInfoTile("Email ID", profile.emailId, true, () => _showEditDialog("Email ID", "emailId", profile.emailId)),
        _buildInfoTile("Mobile Number", profile.mobileNumber, false, null),
        _buildInfoTile("Date of Birth", profile.dateOfBirth, false, null),
        _buildInfoTile("Address", profile.communicationAddress, true, () => _showEditDialog("Address", "communicationAddress", profile.communicationAddress)),
      ],
    );
  }

  Widget _buildKycTab(ProfileData profile) {
    return ListView(
      padding: const EdgeInsets.all(kPaddingMedium),
      children: [
        _buildInfoTile("Aadhaar Number", profile.kycDetails.aadhaarNumber, false, null),
        _buildInfoTile("PAN Number", profile.kycDetails.panNumber, false, null),
        const SizedBox(height: 20),
        const Text("KYC Status: Verified", style: TextStyle(color: kSuccessGreen, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, bool editable, VoidCallback? onEdit) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black)),
          trailing: editable ? TextButton(onPressed: onEdit, child: const Text("EDIT", style: TextStyle(color: kAccentOrange, fontWeight: FontWeight.bold))) : null,
        ),
        const Divider(),
      ],
    );
  }

  void _showEditDialog(String title, String key, String initialValue) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Edit $title"),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: "Enter $title")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              ref.read(profileProvider.notifier).updateProfileField(key, controller.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: kAccentOrange),
            child: const Text("SAVE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}