/// Events screen — manage calendar events for outfit planning.
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/models/event_model.dart';
import '../../data/services/api_client.dart';
import '../../shared/widgets/widgets.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<EventItem> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final json = await ApiClient.listEvents();
      _events = json.map((e) => EventItem.fromJson(e as Map<String, dynamic>)).toList();
      _events.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    } catch (_) {
      _error = 'Failed to load events.';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteEvent(int id) async {
    try {
      await ApiClient.deleteEvent(id);
      setState(() => _events.removeWhere((e) => e.id == id));
      if (mounted) showAppSnackBar(context, 'Event deleted');
    } catch (_) {
      if (mounted) showAppSnackBar(context, 'Failed to delete', isError: true);
    }
  }

  void _showAddDialog() {
    showDialog(context: context, builder: (_) => AddEventDialog(onSaved: _loadEvents));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: _isLoading
          ? const LoadingSpinner()
          : _error != null
              ? ErrorDisplay(message: _error!, onRetry: _loadEvents)
              : _events.isEmpty
                  ? EmptyState(
                      title: 'No Events Yet',
                      subtitle: 'Add upcoming events to get outfit suggestions.',
                      icon: Icons.event_outlined,
                      onAction: _showAddDialog,
                      actionLabel: 'Add Event',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadEvents,
                      color: AppTheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _events.length,
                        itemBuilder: (ctx, i) => _buildEventCard(_events[i]),
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventCard(EventItem event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Row(
          children: [
            // Date badge
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(event.eventDate.day.toString(),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accent)),
                  Text(_monthShort(event.eventDate.month),
                      style: const TextStyle(fontSize: 11, color: AppTheme.accent)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text('${event.eventDate.hour}:${event.eventDate.minute.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(event.eventType,
                            style: const TextStyle(color: AppTheme.primary, fontSize: 10)),
                      ),
                    ],
                  ),
                  if (event.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(event.location!,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                  if (event.dressCode != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.checkroom_outlined, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text('Dress code: ${event.dressCode}',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Delete
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.textSecondary),
              onPressed: () => _deleteEvent(event.id),
            ),
          ],
        ),
      ),
    );
  }

  String _monthShort(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

// ─── Add Event Dialog ─────────────────────────────

class AddEventDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const AddEventDialog({super.key, required this.onSaved});

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _eventType = 'casual_outing';
  String? _dressCode;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  bool _isSaving = false;

  static const _eventTypes = EventType.all;
  static const _dressCodes = EventType.dressCodes;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final dateTime = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _selectedTime.hour, _selectedTime.minute,
    );

    try {
      await ApiClient.createEvent({
        'title': _titleCtrl.text.trim(),
        'event_type': _eventType,
        'event_date': dateTime.toIso8601String(),
        if (_locationCtrl.text.isNotEmpty) 'location': _locationCtrl.text.trim(),
        if (_dressCode != null) 'dress_code': _dressCode,
      });
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        showAppSnackBar(context, 'Event added!');
      }
    } catch (_) {
      if (mounted) showAppSnackBar(context, 'Failed to add event', isError: true);
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Event'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Event Title *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _eventType,
                decoration: const InputDecoration(labelText: 'Event Type'),
                items: _eventTypes.map((e) =>
                  DropdownMenuItem(value: e, child: Text(e.replaceAll('_', ' ')))).toList(),
                onChanged: (v) => setState(() => _eventType = v!),
              ),
              const SizedBox(height: 12),
              // Date + Time pickers
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Date'),
                          initialValue: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickTime,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Time'),
                          initialValue: '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(labelText: 'Location (optional)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _dressCode,
                decoration: const InputDecoration(labelText: 'Dress Code (optional)'),
                items: _dressCodes.map((d) =>
                  DropdownMenuItem(value: d, child: Text(d.replaceAll('_', ' ')))).toList(),
                onChanged: (v) => setState(() => _dressCode = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(height: 18, width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Add'),
        ),
      ],
    );
  }
}
