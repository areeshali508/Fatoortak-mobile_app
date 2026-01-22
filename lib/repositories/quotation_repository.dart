import '../models/quotation.dart';

class QuotationRepository {
  final List<Quotation> _quotations = <Quotation>[];

  Future<List<Quotation>> listQuotations() async {
    return List<Quotation>.unmodifiable(_quotations);
  }

  Future<void> addQuotation(Quotation quotation) async {
    _quotations.insert(0, quotation);
  }
}
