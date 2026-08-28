part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

extension _ProductCalibrationActions on _ProductCalibrationScreenState {
  Future<void> _confirmDeleteWornPhoto() async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      title: 'Remove worn photo?',
      subtitle: 'You can upload another photo afterwards.',
      icon: Icons.delete_outline,
      iconBackgroundColor: AppColors.dangerDark,
      builder: (_) => const Padding(
        padding: EdgeInsets.all(20),
        child: Text('This removes the current worn-photo candidate.'),
      ),
      footer: AppDialogActionFooter(
        primaryLabel: 'Remove photo',
        danger: true,
        onCancel: () => Navigator.pop(context, false),
        onPrimary: () => Navigator.pop(context, true),
      ),
    );
    if (confirmed != true || !mounted) return;
    final fence = _currentFence();
    if (fence == null || _isMutating) return;
    _isMutating = true;
    final result = await widget.repository.deleteWornPhoto(
      widget.product.id,
      fence,
    );
    if (!mounted) return;
    _isMutating = false;
    if (result case Err(:final failure)) {
      AppSnackBar.showError(context, failure.message);
      await _load();
      return;
    }
    await _load();
    if (mounted) _step = _CalibrationStep.wornPhoto;
  }

  Future<void> _confirmDiscardChanges() async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      title: 'Discard calibration changes?',
      subtitle: 'Your active calibration will stay available for shoots.',
      icon: Icons.restore,
      iconBackgroundColor: AppColors.dangerDark,
      builder: (dialogContext) => const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'This removes the current candidate and restores the last approved size. A first-time draft will be deleted.',
        ),
      ),
      footer: AppDialogActionFooter(
        primaryLabel: 'Discard changes',
        danger: true,
        onCancel: () => Navigator.pop(context, false),
        onPrimary: () => Navigator.pop(context, true),
      ),
    );
    if ((confirmed ?? false) && mounted) await _discardChanges();
  }

  CalibrationMutationFence? _currentFence() {
    final calibration = _workspace?.calibration;
    if (calibration == null) return null;
    return CalibrationMutationFence(
      calibrationId: calibration.id,
      revision: calibration.revision,
      mutationId: _newMutationId(),
    );
  }

  Future<void> _continueToFit() async {
    final fence = _currentFence();
    final cutout = _cutout;
    if (fence == null || cutout == null) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Reload calibration, then place the product again.',
        );
      }
      return;
    }
    _isMutating = true;
    final placement = {
      'bodyArea': _bodyArea,
      'placement': _placementPayload(),
    };
    final result = await widget.repository.uploadPlacement(
      widget.product.id,
      cutout,
      placement,
      fence,
    );
    if (!mounted) return;
    _isMutating = false;
    if (result case Err(:final failure)) {
      _failure = failure;
      AppSnackBar.showError(context, failure.message);
      await _load();
      return;
    }
    await _load();
    if (!mounted) return;
    _step = _CalibrationStep.fit;
    await _startRender();
  }

  Map<String, dynamic> _placementPayload() => {
    'x': _placementX * 1000,
    'y': _placementY * 1500,
    'w': 220 * _placementScale,
    'h': 260 * _placementScale,
    'rotation': _placementRotation,
  };

  Future<void> _startRender({bool regenerate = false}) async {
    if (_isMutating) return;
    final feedback = _renderFeedbackController.text.trim();
    if (feedback.length > 300) {
      AppSnackBar.showError(
        context,
        'Render feedback is limited to 300 characters.',
      );
      return;
    }
    _isMutating = true;
    final prior = regenerate ? _renders.firstOrNull?.id : null;
    final result = await widget.repository.startCalibrationRender(
      widget.product.id,
      bodyPreset: _bodyPreset,
      mutationId: _newMutationId(),
      feedback: feedback.isEmpty ? null : feedback,
      previousRenderId: prior,
    );
    if (!mounted) return;
    _isMutating = false;
    switch (result) {
      case Ok(:final value):
        _renders = [
          value,
          ..._renders.where((render) => render.id != value.id),
        ];
        _renderFeedbackController.clear();
        _startRenderPolling();
      case Err(:final failure):
        _failure = failure;
        AppSnackBar.showError(context, failure.message);
    }
  }

  void _startRenderPolling() {
    _renderPollTimer?.cancel();
    _renderPollStartedAt = DateTime.now();
    _renderPollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => unawaited(_pollRender()),
    );
  }

  Future<void> _pollRender() async {
    final started = _renderPollStartedAt;
    if (!mounted ||
        started == null ||
        DateTime.now().difference(started) >= const Duration(minutes: 10)) {
      _renderPollTimer?.cancel();
      return;
    }
    final result = await widget.repository.getLatestCalibrationRender(
      widget.product.id,
    );
    if (!mounted || result is! Ok<CalibrationRender?>) return;
    final render = result.valueOrNull;
    if (render == null) return;
    _renders = [
      render,
      ..._renders.where((item) => item.id != render.id),
    ];
    if (!render.status.isPending) _renderPollTimer?.cancel();
  }

  Future<void> _approveRender() async {
    final render = _renders.firstOrNull;
    final fence = _currentFence();
    if (render?.isApprovalEligible != true || fence == null || _isMutating) {
      return;
    }
    _isMutating = true;
    final result = await widget.repository.approveCalibrationRender(
      widget.product.id,
      render!.id,
      fence,
    );
    if (!mounted) return;
    _isMutating = false;
    if (result case Err(:final failure)) {
      AppSnackBar.showError(context, failure.message);
      await _load();
      return;
    }
    await _load();
    if (mounted) _step = _CalibrationStep.review;
  }

  Future<void> _discardChanges() async {
    final fence = _currentFence();
    if (fence == null || _isMutating) return;
    _isMutating = true;
    final result = await widget.repository.discardCalibrationCandidate(
      widget.product.id,
      fence,
    );
    if (!mounted) return;
    _isMutating = false;
    if (result case Err(:final failure)) {
      AppSnackBar.showError(context, failure.message);
      await _load();
      return;
    }
    widget.onSaved();
    Navigator.pop(context);
  }
}

extension _ProductCalibrationSaveActions on _ProductCalibrationScreenState {
  Future<void> _uploadWornPhoto() async {
    final upload = await _pickUpload('Upload worn product photo');
    if (upload == null || !mounted) return;
    final calibration = _workspace?.calibration;
    if (calibration == null) {
      AppSnackBar.showError(
        context,
        'Could not load the current calibration. Please try again.',
      );
      return;
    }
    _isMutating = true;
    final result = await widget.repository.uploadWornPhoto(
      widget.product.id,
      upload,
      calibrationId: calibration.id,
      revision: calibration.revision,
      mutationId: _newMutationId(),
    );
    if (!mounted) return;
    _isMutating = false;
    final failure = result.failureOrNull;
    if (failure != null) {
      AppSnackBar.showError(context, failure.message);
      await _load();
      return;
    }
    await _load();
    if (mounted) _step = _CalibrationStep.review;
  }

  String _newMutationId() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<void> _save() async {
    if (_isMutating) return;
    final fence = _currentFence();
    if (fence == null) {
      AppSnackBar.showError(
        context,
        'Could not load the current calibration. Please try again.',
      );
      return;
    }
    _isMutating = true;
    final calibration = _workspace?.calibration;
    if (calibration?.status == ProductCalibrationStatus.saveReady) {
      final promoted = await widget.repository.promoteCalibrationCandidate(
        widget.product.id,
        fence,
      );
      if (!mounted) return;
      _isMutating = false;
      if (promoted case Err(:final failure)) {
        AppSnackBar.showError(context, failure.message);
        await _load();
        return;
      }
      widget.onSaved();
      Navigator.pop(context);
      return;
    }
    final hasPlacement = calibration?.cutoutUrl != null || _cutout != null;
    if (!hasPlacement && calibration?.wornPhotoUrl == null) {
      _isMutating = false;
      AppSnackBar.showError(
        context,
        'Place the product on the body outline first.',
      );
      return;
    }
    final result = await widget.repository.saveCalibration(
      widget.product.id,
      ProductCalibrationDraft(
        bodyArea: _bodyArea,
        shapes: const [],
        userNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        cutoutPlacement: hasPlacement
            ? {
                'x': _placementX * 1000,
                'y': _placementY * 1500,
                'w': 220 * _placementScale,
                'h': 260 * _placementScale,
              }
            : null,
        fence: fence,
      ),
    );
    if (!mounted) return;
    _isMutating = false;
    final failure = result.failureOrNull;
    if (failure != null) {
      AppSnackBar.showError(context, failure.message);
      await _load();
      return;
    }
    widget.onSaved();
    Navigator.pop(context);
  }

  Future<void> _copyFrom(ProductCatalogItem source) async {
    if (_isMutating) return;
    final fence = _currentFence();
    if (fence == null) {
      AppSnackBar.showError(context, 'Reload calibration, then try again.');
      return;
    }
    _isMutating = true;
    final result = await widget.repository.copyCalibration(
      widget.product.id,
      source.id,
      fence,
    );
    if (!mounted) return;
    _isMutating = false;
    final failure = result.failureOrNull;
    if (failure != null) {
      AppSnackBar.showError(context, failure.message);
      await _load();
      return;
    }
    await _load();
    if (!mounted) return;
    final calibration = _workspace?.calibration;
    if (calibration?.wornPhotoUrl != null ||
        calibration?.status == ProductCalibrationStatus.saveReady) {
      _step = _CalibrationStep.review;
      return;
    }
    _step = _CalibrationStep.fit;
    await _startRender();
  }
}
