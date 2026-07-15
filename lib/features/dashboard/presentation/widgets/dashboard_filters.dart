part of '../screens/dashboard_screen.dart';

class _FilterCard extends StatelessWidget {
  const _FilterCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(12),
      child: _Stack(gap: 10, children: children),
    );
  }
}

class _InputLike extends StatelessWidget {
  const _InputLike(this.placeholder, {this.label});

  final String placeholder;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[_FieldLabel(label!), const SizedBox(height: 6)],
        AppTextField(
          controller: TextEditingController(
            text: label == null ? null : placeholder,
          ),
          hintText: label == null ? placeholder : null,
        ),
      ],
    );
  }
}

class _SelectLike extends StatelessWidget {
  const _SelectLike(this.value, {this.label});

  final String value;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[_FieldLabel(label!), const SizedBox(height: 6)],
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.neutral200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: AppColors.black),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: AppColors.neutral500,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TextAreaLike extends StatelessWidget {
  const _TextAreaLike(this.placeholder, {this.label});

  final String placeholder;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[_FieldLabel(label!), const SizedBox(height: 6)],
        AppTextField(
          minLines: 4,
          maxLines: 6,
          controller: TextEditingController(
            text: label == null ? null : placeholder,
          ),
          hintText: label == null ? placeholder : null,
        ),
      ],
    );
  }
}

class _UploadBox extends StatelessWidget {
  const _UploadBox({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 6),
        Container(
          height: 132,
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            border: Border.all(color: AppColors.neutral200),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.upload, size: 30, color: AppColors.black),
                SizedBox(height: 8),
                _CardTitle('Click to upload'),
                _Caption('PNG, JPG up to 10MB'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
