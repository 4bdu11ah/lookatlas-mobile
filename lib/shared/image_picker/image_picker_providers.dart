import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// The app-wide [ImagePicker]. Controllers read this instead of constructing
/// their own so widget tests can override it with a fake.
final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());
