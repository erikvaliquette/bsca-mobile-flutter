import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;

import 'permission_service.dart';

/// A service to handle image picking and processing
class ImageService {
  static final ImageService _instance = ImageService._internal();
  
  factory ImageService() {
    return _instance;
  }
  
  ImageService._internal();
  
  static ImageService get instance => _instance;
  
  final ImagePicker _picker = ImagePicker();
  
  /// Show a modal bottom sheet with options to pick an image from gallery or camera
  Future<File?> pickImage(BuildContext context, {
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
    
    if (source == null) return null;
    
    // Check for appropriate permission based on source
    bool hasPermission = false;
    if (source == ImageSource.camera) {
      hasPermission = await PermissionService.instance.handlePermission(
        context,
        permission_handler.Permission.camera,
        'Camera',
        'This app needs camera access to take photos. Please grant camera permission to use this feature.',
      );
    } else {
      hasPermission = await PermissionService.instance.handlePermission(
        context,
        permission_handler.Permission.photos,
        'Photos',
        'This app needs access to your photos to select images. Please grant photos permission to use this feature.',
      );
    }
    
    if (!hasPermission) return null;
    
    return await getImageFromSource(
      source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }
  
  /// Get an image from the specified source
  Future<File?> getImageFromSource(
    ImageSource source, {
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: maxWidth ?? 800,
      maxHeight: maxHeight ?? 800,
      imageQuality: imageQuality ?? 85,
    );
    
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    
    return null;
  }
}
