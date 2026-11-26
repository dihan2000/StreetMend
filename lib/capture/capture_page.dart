import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../brand.dart';
import 'location_picker_page.dart';
import 'report_draft.dart';
import 'review_report_page.dart';
import 'services/photo_service.dart';
import 'services/location_service.dart';
import 'widgets/draft_photo.dart';

class CapturePage extends StatefulWidget {
  const CapturePage({
    super.key,
    this.photoService,
    this.locationService,
    this.recoveredPhoto,
    this.mapBuilder,
    this.reviewMap,
  });
  final PhotoService? photoService;
  final LocationService? locationService;
  final Uint8List? recoveredPhoto;
  final LocationMapBuilder? mapBuilder;
  final Widget? reviewMap;

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
  final _draft = ReportDraft();
  final _form = GlobalKey<FormState>();
  late final _photos = widget.photoService ?? PhotoService();
  bool _busy = false;
  bool _allowExit = false;
  bool _askingExit = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _draft.photo = widget.recoveredPhoto;
    if (widget.recoveredPhoto != null) _message = 'Your selected photo was recovered after Android restarted the app. Please re-enter the remaining details.';
  }

  Future<void> _pick(bool camera) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final bytes = await _photos.pick(camera: camera);
      if (!mounted) return;
      if (bytes != null) setState(() => _draft.photo = bytes);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _message = error is FormatException
            ? error.message
            : error is PlatformException
            ? 'Photo access is unavailable or was denied. Check camera/photo access in device Settings, or try choosing another photo.'
            : 'Unable to read this photo. Please try another image.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _validate() {
    final valid = _form.currentState!.validate();
    if (_draft.photo == null) {
      setState(() => _message = 'Please take or choose one issue photo.');
    }
    return valid && _draft.photo != null;
  }

  Future<void> _location() async {
    if (!_validate()) return;
    FocusScope.of(context).unfocus();
    final location = await Navigator.of(context).push<IssueLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          initial: _draft.location,
          service: widget.locationService,
          mapBuilder: widget.mapBuilder,
        ),
      ),
    );
    if (!mounted || location == null) return;
    setState(() => _draft.location = location);
    await _review();
  }

  Future<void> _review() async {
    if (!_validate() || !_draft.readyForReview) return;
    final edit = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            ReviewReportPage(draft: _draft, mapPreview: widget.reviewMap),
      ),
    );
    if (!mounted) return;
    if (edit == 'location') await _location();
  }

  Future<void> _exit() async {
    if (_askingExit || _busy) return;
    _askingExit = true;
    final discard =
        !_draft.hasChanges ||
        await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Discard this draft?'),
                content: const Text(
                  'Your photo and entered details are only kept for this session. Nothing has been submitted.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Keep Editing'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Discard Draft'),
                  ),
                ],
              ),
            ) ==
            true;
    _askingExit = false;
    if (!mounted || !discard) return;
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowExit,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _exit();
    },
    child: Scaffold(
      backgroundColor: appColors(context).background,
      appBar: AppBar(
        title: const Text('Report an Issue'),
        leading: IconButton(
          tooltip: 'Close capture',
          onPressed: _busy ? null : _exit,
          icon: const Icon(Icons.close),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '1 of 3 • Tell us what you see',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: appColors(context).ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Document damaged infrastructure. Avoid faces, number plates and other personal information in your photo.',
                ),
                const SizedBox(height: 18),
                if (_draft.photo != null)
                  DraftPhoto(bytes: _draft.photo!)
                else
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: appColors(context).soft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.add_a_photo_outlined,
                        color: appColors(context).ink,
                        size: 48,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _pick(true),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Take Photo'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _pick(false),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Choose Photo'),
                    ),
                    if (_draft.photo != null)
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() => _draft.photo = null),
                        child: const Text('Remove Photo'),
                      ),
                  ],
                ),
                if (_busy) const LinearProgressIndicator(),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _message!,
                      style: TextStyle(color: appColors(context).ink),
                    ),
                  ),
                const SizedBox(height: 18),
                DropdownButtonFormField<IssueCategory>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Issue category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final category in IssueCategory.values)
                      DropdownMenuItem(
                        value: category,
                        child: Text(
                          category.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _draft.category = value),
                  validator: (value) =>
                      value == null ? 'Please choose a category.' : null,
                ),
                const SizedBox(height: 18),
                if (_draft.category == IssueCategory.other) ...[
                  TextFormField(
                    key: const ValueKey('custom-issue-title'),
                    initialValue: _draft.customTitle,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Custom issue title',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _draft.customTitle = value,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please specify the issue title.'
                        : null,
                  ),
                  const SizedBox(height: 18),
                ],
                TextFormField(
                  key: const ValueKey('issue-description'),
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Problem description',
                    hintText:
                        'What is damaged and how does it affect the street?',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _draft.description = value,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please describe the issue.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: 'Location notes / nearby landmark (optional)',
                    helperText:
                        'This text does not set or verify the map location.',
                    helperMaxLines: 3,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _draft.landmark = value,
                ),
                if (_draft.location != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Confirmed location: ${_draft.location!.coordinates}',
                    ),
                  ),
                FilledButton(
                  onPressed: _busy ? null : _location,
                  style: FilledButton.styleFrom(
                    backgroundColor: kFreshTeal,
                    foregroundColor: kOceanNavy,
                  ),
                  child: Text(
                    _draft.location == null
                        ? 'Continue to Location'
                        : 'Edit Location',
                  ),
                ),
                if (_draft.location != null)
                  OutlinedButton(
                    onPressed: _busy ? null : _review,
                    child: const Text('Review Draft'),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Local draft only • Nothing is submitted. Drafts do not survive an app restart.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
