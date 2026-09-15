enum SupportCategory {
  technical('Something not working', 'Something is not working'),
  billing('Billing & credits', 'Billing or credits'),
  account('Account', 'Account or sign-in'),
  usingLookAtlas('How to use', 'How to use Look Atlas'),
  feedback('Feature feedback', 'Feedback or feature idea');

  const SupportCategory(this.label, this.ticketLabel);
  final String label;
  final String ticketLabel;
}

class SupportTicketRequest {
  const SupportTicketRequest({
    required this.title,
    required this.name,
    required this.priority,
    required this.message,
  });
  final String title;
  final String name;
  final String priority;
  final String message;
}

class SupportTicketReceipt {
  const SupportTicketReceipt({
    required this.message,
    required this.provider,
    this.id,
  });
  final String message;
  final String provider;
  final String? id;
}
