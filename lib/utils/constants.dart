// lib/utils/constants.dart

import 'local_constants.dart';

/// The URL of the unified AI proxy (Cloudflare Worker).
/// If you are cloning this project, you must set this in local_constants.dart
const String aiProxyUrl = secretAiProxyUrl;

/// Cloudinary configuration.
/// Set these in local_constants.dart
const String cloudinaryCloudName = secretCloudinaryCloudName;
const String cloudinaryUploadPreset = secretCloudinaryUploadPreset;

/// EmailJS configuration.
/// Set this in local_constants.dart
const String emailJsPublicKey_const = secretEmailJsPublicKey;
