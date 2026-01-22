import '../models/debit_note.dart';

class DebitNoteRepository {
  final List<DebitNote> _notes = <DebitNote>[
    DebitNote(
      id: 'DN-2024-001',
      customer: 'Sarah Jenkins',
      customerType: 'B2C',
      issueDate: DateTime(2024, 10, 12),
      currency: 'SAR',
      amount: 450.00,
      status: DebitNoteStatus.submitted,
      paymentStatus: DebitNotePaymentStatus.pending,
      originalInvoiceNo: 'INV-2024-1102',
      originalInvoiceCustomerType: 'B2C',
      zatcaUuid: 'dn-uuid-001',
      zatcaHash: 'dn-hash-001',
      items: <DebitNoteItem>[
        DebitNoteItem(
          description: 'Service Adjustment',
          qty: 1,
          price: 450.00,
          discountPercent: 0,
          vatCategory: 'Standard',
          taxPercent: 15,
        ),
      ],
    ),
    DebitNote(
      id: 'DN-2024-002',
      customer: 'Abdul Rahman',
      customerType: 'B2B',
      issueDate: DateTime(2024, 11, 2),
      currency: 'SAR',
      amount: 2100.00,
      status: DebitNoteStatus.cleared,
      paymentStatus: DebitNotePaymentStatus.paid,
      originalInvoiceNo: 'INV-2024-1148',
      originalInvoiceCustomerType: 'B2B',
      zatcaUuid: 'dn-uuid-002',
      zatcaHash: 'dn-hash-002',
      items: <DebitNoteItem>[
        DebitNoteItem(
          description: 'Additional Items',
          qty: 2,
          price: 1050.00,
          discountPercent: 0,
          vatCategory: 'Standard',
          taxPercent: 15,
        ),
      ],
    ),
    DebitNote(
      id: 'DN-2024-003',
      customer: 'Omar Farooq',
      customerType: 'B2C',
      issueDate: DateTime(2024, 11, 9),
      currency: 'SAR',
      amount: 320.00,
      status: DebitNoteStatus.rejected,
      paymentStatus: DebitNotePaymentStatus.cancelled,
      originalInvoiceNo: 'INV-2024-1164',
      originalInvoiceCustomerType: 'B2C',
      zatcaErrorMessage: 'Rejected by ZATCA (dummy)',
      items: <DebitNoteItem>[
        DebitNoteItem(
          description: 'Late Fee',
          qty: 1,
          price: 320.00,
          discountPercent: 0,
          vatCategory: 'Standard',
          taxPercent: 15,
        ),
      ],
    ),
  ];

  Future<List<DebitNote>> listDebitNotes() async {
    return List<DebitNote>.unmodifiable(_notes);
  }

  Future<void> addDebitNote(DebitNote note) async {
    _notes.insert(0, note);
  }
}
