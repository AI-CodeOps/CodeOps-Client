/// Jira ticket selection step for bug investigation wizard mode.
///
/// Provides a text field for ticket key entry, a Fetch button, and
/// displays ticket details once fetched. Includes an additional
/// context field. Validation: ticket must be fetched.
library;

import 'package:flutter/material.dart';

import '../../providers/wizard_providers.dart';
import '../../theme/colors.dart';

/// Jira ticket step for the bug investigation wizard flow.
class JiraTicketStep extends StatefulWidget {
  /// The fetched ticket data, or `null` if not yet fetched.
  final JiraTicketData? ticketData;

  /// Called when a ticket is fetched.
  final ValueChanged<String> onFetchTicket;

  /// Additional context text.
  final String additionalContext;

  /// Called when additional context changes.
  final ValueChanged<String> onContextChanged;

  /// Whether a fetch is in progress.
  final bool isFetching;

  /// Error from a failed fetch attempt.
  final String? fetchError;

  /// Creates a [JiraTicketStep].
  const JiraTicketStep({
    super.key,
    this.ticketData,
    required this.onFetchTicket,
    this.additionalContext = '',
    required this.onContextChanged,
    this.isFetching = false,
    this.fetchError,
  });

  @override
  State<JiraTicketStep> createState() => _JiraTicketStepState();
}

class _JiraTicketStepState extends State<JiraTicketStep> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jira Ticket',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter a Jira ticket key to investigate.',
            style: TextStyle(
              color: CodeOpsColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          // Ticket key input + Fetch button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(
                    color: CodeOpsColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'e.g. PROJ-123',
                    hintStyle:
                        TextStyle(color: CodeOpsColors.textTertiary),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    prefixIcon:
                        Icon(Icons.confirmation_num_outlined, size: 18),
                  ),
                  onSubmitted: (v) {
                    if (v.isNotEmpty) widget.onFetchTicket(v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: widget.isFetching
                    ? null
                    : () {
                        if (_controller.text.isNotEmpty) {
                          widget.onFetchTicket(_controller.text);
                        }
                      },
                icon: widget.isFetching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search, size: 16),
                label: Text(widget.isFetching ? 'Fetching...' : 'Fetch'),
                style: FilledButton.styleFrom(
                  backgroundColor: CodeOpsColors.primary,
                ),
              ),
            ],
          ),

          // Error message
          if (widget.fetchError != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.fetchError!,
              style: const TextStyle(
                color: CodeOpsColors.error,
                fontSize: 12,
              ),
            ),
          ],

          // Ticket detail card
          if (widget.ticketData != null) ...[
            const SizedBox(height: 16),
            _TicketDetailCard(ticket: widget.ticketData!),
          ],

          const SizedBox(height: 24),

          // Additional context
          const Text(
            'Additional Context',
            style: TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            maxLines: 4,
            controller:
                TextEditingController(text: widget.additionalContext)
                  ..selection = TextSelection.collapsed(
                      offset: widget.additionalContext.length),
            style: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 13,
            ),
            decoration: const InputDecoration(
              hintText: 'Additional context for bug investigation...',
              hintStyle: TextStyle(color: CodeOpsColors.textTertiary),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
            onChanged: widget.onContextChanged,
          ),
        ],
      ),
    );
  }
}

class _TicketDetailCard extends StatelessWidget {
  final JiraTicketData ticket;

  const _TicketDetailCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CodeOpsColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CodeOpsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: CodeOpsColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ticket.key,
                  style: const TextStyle(
                    color: CodeOpsColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: CodeOpsColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ticket.status,
                  style: const TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: CodeOpsColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ticket.priority,
                  style: const TextStyle(
                    color: CodeOpsColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ticket.summary,
            style: const TextStyle(
              color: CodeOpsColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (ticket.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              ticket.description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CodeOpsColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              if (ticket.assignee != null)
                _MetaChip(
                    label: 'Assignee', value: ticket.assignee!),
              if (ticket.reporter != null)
                _MetaChip(label: 'Reporter', value: ticket.reporter!),
              _MetaChip(
                label: 'Comments',
                value: ticket.commentCount.toString(),
              ),
              _MetaChip(
                label: 'Attachments',
                value: ticket.attachmentCount.toString(),
              ),
              _MetaChip(
                label: 'Linked',
                value: ticket.linkedIssueCount.toString(),
              ),
              if (ticket.sprint != null)
                _MetaChip(label: 'Sprint', value: ticket.sprint!),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetaChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: CodeOpsColors.textTertiary,
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: CodeOpsColors.textPrimary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
