import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/image_service.dart';
import '../../models/profile_model.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/sdg_icon_widget.dart';
import '../../utils/sdg_icons.dart';
import 'edit_work_history_screen.dart';
import 'edit_education_screen.dart';
import 'edit_certification_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Basic profile info controllers
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  
  // Image picker
  File? _imageFile;
  String? _avatarUrl;
  
  // SDG goals
  List<String> _selectedSdgGoals = [];
  
  // Work history, education, and certifications
  List<WorkHistory> _workHistory = [];
  List<Education> _education = [];
  List<Certification> _certifications = [];
  
  // Default settings
  Map<String, dynamic> _preferences = {};
  
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }
  
  void _initializeFormData() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final profile = profileProvider.profile;
    
    if (profile != null) {
      _usernameController.text = profile.username ?? '';
      _fullNameController.text = profile.fullName ?? '';
      _bioController.text = profile.bio ?? '';
      _avatarUrl = profile.avatarUrl;
      
      // Initialize SDG goals
      _selectedSdgGoals = List<String>.from(profile.sdgGoals ?? []);
      
      // Initialize work history
      _workHistory = List<WorkHistory>.from(profile.workHistory ?? []);
      
      // Initialize education
      _education = List<Education>.from(profile.education ?? []);
      
      // Initialize certifications
      _certifications = List<Certification>.from(profile.certifications ?? []);
      
      // Initialize preferences
      _preferences = Map<String, dynamic>.from(profile.preferences ?? {});
    }
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
  
  // Image picker method
  Future<void> _pickImage() async {
    final File? pickedFile = await ImageService.instance.pickImage(
      context,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      String? newAvatarUrl = _avatarUrl;
      
      // Upload new image if selected
      if (_imageFile != null) {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileExtension = _imageFile!.path.split('.').last;
        final fileName = '$userId-$timestamp.$fileExtension';
        
        try {
          // Upload to Supabase Storage
          final response = await Supabase.instance.client.storage
              .from('avatars')
              .upload('avatars/$fileName', _imageFile!);
          
          // Get public URL
          final String publicUrl = Supabase.instance.client.storage
              .from('avatars')
              .getPublicUrl('avatars/$fileName');
          
          newAvatarUrl = publicUrl;
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading image: $e')),
          );
        }
      }
      
      // Update profile
      await profileProvider.updateFullProfile(
        username: _usernameController.text,
        fullName: _fullNameController.text,
        avatarUrl: newAvatarUrl,
        bio: _bioController.text,
        sdgGoals: _selectedSdgGoals,
        workHistory: _workHistory,
        education: _education,
        certifications: _certifications,
        preferences: _preferences,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading 
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2)
                )
              : const Text('SAVE'),
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Picture Section
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (_avatarUrl != null
                                  ? NetworkImage(_avatarUrl!) as ImageProvider
                                  : null),
                          child: (_imageFile == null && _avatarUrl == null)
                              ? Text(
                                  _getInitials(_fullNameController.text),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            radius: 20,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, color: Colors.white),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Basic Info Section
                  _buildSectionTitle(context, 'Basic Information'),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'Enter your username',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your full name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      hintText: 'Tell us about yourself',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  
                  // SDG Goals Section
                  _buildSectionTitle(context, 'SDG Goals'),
                  _buildSdgGoalsSelector(),
                  const SizedBox(height: 24),
                  
                  // Work History Section
                  _buildSectionTitle(context, 'Work History'),
                  _buildWorkHistoryList(),
                  const SizedBox(height: 24),
                  
                  // Education Section
                  _buildSectionTitle(context, 'Education'),
                  _buildEducationList(),
                  const SizedBox(height: 24),
                  
                  // Certifications Section
                  _buildSectionTitle(context, 'Certifications'),
                  _buildCertificationsList(),
                  const SizedBox(height: 24),
                  
                  // Default Settings Section
                  _buildSectionTitle(context, 'Default Settings'),
                  _buildDefaultSettings(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
    );
  }
  
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }
  
  Widget _buildSdgGoalsSelector() {
    // Map SDG numbers to their names
    final Map<int, String> sdgMap = {
      1: 'No Poverty',
      2: 'Zero Hunger',
      3: 'Good Health and Well-being',
      4: 'Quality Education',
      5: 'Gender Equality',
      6: 'Clean Water and Sanitation',
      7: 'Affordable and Clean Energy',
      8: 'Decent Work and Economic Growth',
      9: 'Industry, Innovation and Infrastructure',
      10: 'Reduced Inequality',
      11: 'Sustainable Cities and Communities',
      12: 'Responsible Consumption and Production',
      13: 'Climate Action',
      14: 'Life Below Water',
      15: 'Life on Land',
      16: 'Peace, Justice and Strong Institutions',
      17: 'Partnerships for the Goals',
    };
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select the SDG goals that align with your interests:'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: sdgMap.entries.map((entry) {
            final int sdgNumber = entry.key;
            final String goalName = entry.value;
            final bool isSelected = _selectedSdgGoals.contains(goalName);
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedSdgGoals.remove(goalName);
                  } else {
                    _selectedSdgGoals.add(goalName);
                  }
                });
              },
              child: Stack(
                children: [
                  SDGIconWidget(
                    sdgNumber: sdgNumber,
                    size: 60.0,
                    showLabel: false,
                  ),
                  if (isSelected)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildWorkHistoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._workHistory.asMap().entries.map((entry) {
          final index = entry.key;
          final work = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          work.company ?? 'Company',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _workHistory.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                  Text(work.position ?? 'Position'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _editWorkHistory(index),
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _addWorkHistory(),
          icon: const Icon(Icons.add),
          label: const Text('Add Work Experience'),
        ),
      ],
    );
  }
  
  Future<void> _addWorkHistory() async {
    final result = await Navigator.of(context).push<WorkHistory>(
      MaterialPageRoute(
        builder: (context) => const EditWorkHistoryScreen(),
      ),
    );
    
    if (result != null) {
      setState(() {
        _workHistory.add(result);
      });
    }
  }
  
  Future<void> _editWorkHistory(int index) async {
    final result = await Navigator.of(context).push<WorkHistory>(
      MaterialPageRoute(
        builder: (context) => EditWorkHistoryScreen(workHistory: _workHistory[index]),
      ),
    );
    
    if (result != null) {
      setState(() {
        _workHistory[index] = result;
      });
    }
  }
  
  Widget _buildEducationList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._education.asMap().entries.map((entry) {
          final index = entry.key;
          final edu = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          edu.institution ?? 'Institution',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _education.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                  Text(edu.degree ?? 'Degree'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _editEducation(index),
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _addEducation(),
          icon: const Icon(Icons.add),
          label: const Text('Add Education'),
        ),
      ],
    );
  }
  
  Future<void> _addEducation() async {
    final result = await Navigator.of(context).push<Education>(
      MaterialPageRoute(
        builder: (context) => const EditEducationScreen(),
      ),
    );
    
    if (result != null) {
      setState(() {
        _education.add(result);
      });
    }
  }
  
  Future<void> _editEducation(int index) async {
    final result = await Navigator.of(context).push<Education>(
      MaterialPageRoute(
        builder: (context) => EditEducationScreen(education: _education[index]),
      ),
    );
    
    if (result != null) {
      setState(() {
        _education[index] = result;
      });
    }
  }
  
  Widget _buildCertificationsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._certifications.asMap().entries.map((entry) {
          final index = entry.key;
          final cert = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          cert.name ?? 'Certification',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _certifications.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                  Text(cert.issuingOrganization ?? 'Issuing Organization'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _editCertification(index),
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _addCertification(),
          icon: const Icon(Icons.add),
          label: const Text('Add Certification'),
        ),
      ],
    );
  }
  
  Future<void> _addCertification() async {
    final result = await Navigator.of(context).push<Certification>(
      MaterialPageRoute(
        builder: (context) => const EditCertificationScreen(),
      ),
    );
    
    if (result != null) {
      setState(() {
        _certifications.add(result);
      });
    }
  }
  
  Future<void> _editCertification(int index) async {
    final result = await Navigator.of(context).push<Certification>(
      MaterialPageRoute(
        builder: (context) => EditCertificationScreen(certification: _certifications[index]),
      ),
    );
    
    if (result != null) {
      setState(() {
        _certifications[index] = result;
      });
    }
  }
  
  Widget _buildDefaultSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Email Notifications'),
          subtitle: const Text('Receive email notifications about updates'),
          value: _preferences['email_notifications'] ?? true,
          onChanged: (value) {
            setState(() {
              _preferences['email_notifications'] = value;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Push Notifications'),
          subtitle: const Text('Receive push notifications on your device'),
          value: _preferences['push_notifications'] ?? true,
          onChanged: (value) {
            setState(() {
              _preferences['push_notifications'] = value;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Public Profile'),
          subtitle: const Text('Make your profile visible to other users'),
          value: _preferences['public_profile'] ?? false,
          onChanged: (value) {
            setState(() {
              _preferences['public_profile'] = value;
            });
          },
        ),
        ListTile(
          title: const Text('Language'),
          subtitle: Text(_preferences['language'] ?? 'English'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            // Show language selection dialog
            _showLanguageSelectionDialog();
          },
        ),
      ],
    );
  }
  
  void _showLanguageSelectionDialog() {
    final languages = ['English', 'French', 'Spanish', 'German', 'Chinese', 'Japanese'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: languages.map((language) {
              return ListTile(
                title: Text(language),
                trailing: _preferences['language'] == language
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() {
                    _preferences['language'] = language;
                  });
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }
}

// Helper function to get initials from name
String _getInitials(String name) {
  if (name.isEmpty) return '';
  final nameParts = name.split(' ');
  if (nameParts.length > 1) {
    return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
  }
  return name.isNotEmpty ? name[0].toUpperCase() : '';
}
