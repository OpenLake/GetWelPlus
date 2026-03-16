import 'package:flutter/material.dart';
import 'package:flutter_app/models/meeting_model.dart';
import 'package:intl/intl.dart';

class MeetingCard extends StatelessWidget {
  final Meeting meeting;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onJoin;

  const MeetingCard({
    super.key,
    required this.meeting,
    required this.onTap,
    this.onCancel,
    this.onJoin,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF4CAF50);
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Finished';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  bool get _isJoinable {
    final now = DateTime.now();
    final diff = meeting.scheduledAt.difference(now).inMinutes;
    return diff <= 5 && diff >= -30;
  }

  bool get _isCancellable =>
      meeting.status == 'pending' || meeting.status == 'confirmed';

  String get _displayStatus {
    if (meeting.isAttended && meeting.status == 'confirmed') return 'completed';
    return meeting.status;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon — changes based on meetingType
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _statusColor(_displayStatus).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      meeting.isChat
                          ? Icons.chat_outlined
                          : Icons.videocam_outlined,
                      color: _statusColor(_displayStatus),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                meeting.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(_displayStatus)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _statusLabel(_displayStatus),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _statusColor(_displayStatus),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          meeting.notes,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('MMM d, yyyy · h:mm a')
                              .format(meeting.scheduledAt),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: const Color(0xFF4CAF50)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (onCancel != null || onJoin != null)
                if (_displayStatus != 'cancelled' &&
                    _displayStatus != 'completed') ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (meeting.status == 'confirmed') ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isJoinable
                                  ? const Color(0xFF4CAF50)
                                  : Colors.grey.shade800,
                              foregroundColor:
                                  _isJoinable ? Colors.black : Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: _isJoinable ? onJoin : null,
                            // Icon + label change based on meetingType
                            icon: Icon(
                              meeting.isChat
                                  ? Icons.chat_outlined
                                  : Icons.video_call_outlined,
                              size: 18,
                            ),
                            label: Text(
                              meeting.isChat
                                  ? (_isJoinable ? 'Open Chat' : 'Not Yet')
                                  : (_isJoinable ? 'Join' : 'Not Yet'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (_isCancellable)
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: onCancel,
                            icon: const Icon(Icons.cancel_outlined, size: 18),
                            label: const Text(
                              'Cancel',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}