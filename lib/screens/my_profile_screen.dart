import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/nostr_profile.dart';
import '../services/key_management_service.dart';
import '../services/nostr_service.dart';
import '../services/service_migration_helper.dart';
import '../services/ndk_backup/ndk_service.dart';
import '../services/ndk_backup/adapters/profile_adapter.dart';
import '../widgets/gradient_background.dart';
import '../utils/validation.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _aboutController = TextEditingController();
  final _pictureController = TextEditingController();
  final _bannerController = TextEditingController();
  final _nip05Controller = TextEditingController();
  final _lud16Controller = TextEditingController();
  final _websiteController = TextEditingController();
  
  final KeyManagementService _keyService = KeyManagementService();
  final NostrService _nostrService = NostrService();
  final NdkService _ndkService = NdkService.instance;
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _currentPubkey;
  NostrProfile? _currentProfile;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }
  
  Future<void> _loadCurrentProfile() async {
    try {
      // Check if user is logged in
      final hasPrivateKey = await _keyService.hasPrivateKey();
      if (!hasPrivateKey) {
        if (mounted) {
          _showError('Please login to edit your profile');
          Navigator.of(context).pop();
        }
        return;
      }
      
      // Get current user's pubkey
      final pubkey = await _keyService.getPublicKey();
      if (pubkey == null) {
        if (mounted) {
          _showError('Could not get your public key');
          Navigator.of(context).pop();
        }
        return;
      }
      
      setState(() {
        _currentPubkey = pubkey;
      });
      
      // Fetch current profile from relays
      final profile = await _nostrService.getProfile(pubkey);
      
      if (profile != null) {
        setState(() {
          _currentProfile = profile;
          _nameController.text = profile.name ?? '';
          _displayNameController.text = profile.displayName ?? '';
          _aboutController.text = profile.about ?? '';
          _pictureController.text = profile.picture ?? '';
          _bannerController.text = profile.banner ?? '';
          _nip05Controller.text = profile.nip05 ?? '';
          _lud16Controller.text = profile.lud16 ?? '';
          _websiteController.text = profile.website ?? '';
        });
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showError('Failed to load profile: ${e.toString()}');
      }
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Create updated profile
      final updatedProfile = NostrProfile(
        pubkey: _currentPubkey!,
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        displayName: _displayNameController.text.trim().isEmpty ? null : _displayNameController.text.trim(),
        about: _aboutController.text.trim().isEmpty ? null : _aboutController.text.trim(),
        picture: _pictureController.text.trim().isEmpty ? null : _pictureController.text.trim(),
        banner: _bannerController.text.trim().isEmpty ? null : _bannerController.text.trim(),
        nip05: _nip05Controller.text.trim().isEmpty ? null : _nip05Controller.text.trim(),
        lud16: _lud16Controller.text.trim().isEmpty ? null : _lud16Controller.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        createdAt: DateTime.now(),
      );
      
      // Use NDK to publish profile update
      if (ServiceMigrationHelper.isUsingNdk && _ndkService.isInitialized) {
        final profileAdapter = ProfileAdapter(_ndkService);
        final success = await profileAdapter.publishProfile(updatedProfile);
        
        if (success) {
          if (mounted) {
            _showSuccess('Profile updated successfully!');
            // Update current profile
            setState(() {
              _currentProfile = updatedProfile;
            });
          }
        } else {
          throw Exception('Failed to publish profile update');
        }
      } else {
        // Fallback to legacy service
        await _nostrService.publishProfile(updatedProfile);
        if (mounted) {
          _showSuccess('Profile updated successfully!');
          setState(() {
            _currentProfile = updatedProfile;
          });
        }
      }
    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        _showError('Failed to save profile: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _aboutController.dispose();
    _pictureController.dispose();
    _bannerController.dispose();
    _nip05Controller.dispose();
    _lud16Controller.dispose();
    _websiteController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Picture Preview
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: _pictureController.text.isNotEmpty
                                  ? CachedNetworkImageProvider(_pictureController.text)
                                  : null,
                              child: _pictureController.text.isEmpty
                                  ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Theme.of(context).primaryColor,
                                child: IconButton(
                                  icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                                  onPressed: () {
                                    // Show dialog to edit picture URL
                                    _showEditPictureDialog();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Username
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          hintText: 'satoshi',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                        validator: (value) {
                          if (value != null && value.length > 32) {
                            return 'Username must be 32 characters or less';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Display Name
                      TextFormField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                          hintText: 'Satoshi Nakamoto',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value != null && value.length > 50) {
                            return 'Display name must be 50 characters or less';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // About/Bio
                      TextFormField(
                        controller: _aboutController,
                        decoration: const InputDecoration(
                          labelText: 'About',
                          hintText: 'Tell us about yourself...',
                          prefixIcon: Icon(Icons.info_outline),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value != null && value.length > 500) {
                            return 'About must be 500 characters or less';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Website
                      TextFormField(
                        controller: _websiteController,
                        decoration: const InputDecoration(
                          labelText: 'Website',
                          hintText: 'https://example.com',
                          prefixIcon: Icon(Icons.link),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!isValidUrl(value)) {
                              return 'Please enter a valid URL';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // NIP-05 Identifier
                      TextFormField(
                        controller: _nip05Controller,
                        decoration: const InputDecoration(
                          labelText: 'NIP-05 Identifier',
                          hintText: 'name@domain.com',
                          prefixIcon: Icon(Icons.verified),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!value.contains('@') || value.split('@').length != 2) {
                              return 'Invalid NIP-05 format (should be name@domain.com)';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Lightning Address
                      TextFormField(
                        controller: _lud16Controller,
                        decoration: const InputDecoration(
                          labelText: 'Lightning Address',
                          hintText: 'satoshi@getalby.com',
                          prefixIcon: Icon(Icons.bolt, color: Colors.orange),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!value.contains('@') || value.split('@').length != 2) {
                              return 'Invalid Lightning address format';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Banner URL
                      TextFormField(
                        controller: _bannerController,
                        decoration: const InputDecoration(
                          labelText: 'Banner Image URL',
                          hintText: 'https://example.com/banner.jpg',
                          prefixIcon: Icon(Icons.panorama),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!isValidUrl(value)) {
                              return 'Please enter a valid URL';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Save Button
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Save Profile',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Public Key Display
                      if (_currentPubkey != null) ...[
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Public Key',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          _currentPubkey!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
  
  void _showEditPictureDialog() {
    final tempController = TextEditingController(text: _pictureController.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Picture URL'),
        content: TextField(
          controller: tempController,
          decoration: const InputDecoration(
            labelText: 'Image URL',
            hintText: 'https://example.com/avatar.jpg',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _pictureController.text = tempController.text;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}