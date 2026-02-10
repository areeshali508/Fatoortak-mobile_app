class Customer {
  final String id;
  final String companyId;
  final String name;
  final String nameAr;
  final String email;
  final String phone;
  final String contactPerson;

  final String customerType;
  final String customerGroup;
  final String taxId;
  final String commercialRegistrationNumber;
  final String industry;
  final String website;
  final String notes;

  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String buildingNumber;
  final String district;
  final String addressAdditionalNumber;

  final String bankName;
  final String accountNumber;
  final String iban;
  final String swiftCode;
  final String currency;

  final num creditLimit;
  final num discount;

  final num dailyLimit;
  final num monthlyLimit;
  final num perTransactionLimit;

  final String status;
  final String verificationStatus;
  final bool isActive;
  final String referenceNumber;

  final List<String> tags;
  final String source;
  final String priority;
  final String assignedTo;
  final num totalPaymentsReceived;
  final num paymentCount;
  final DateTime? lastPaymentDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Customer({
    required this.id,
    this.companyId = '',
    required this.name,
    this.nameAr = '',
    required this.email,
    required this.phone,
    this.contactPerson = '',

    this.customerType = '',
    this.customerGroup = '',
    this.taxId = '',
    this.commercialRegistrationNumber = '',
    this.industry = '',
    this.website = '',
    this.notes = '',

    this.street = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.country = '',
    this.buildingNumber = '',
    this.district = '',
    this.addressAdditionalNumber = '',

    this.bankName = '',
    this.accountNumber = '',
    this.iban = '',
    this.swiftCode = '',
    this.currency = '',

    this.creditLimit = 0,
    this.discount = 0,

    this.dailyLimit = 0,
    this.monthlyLimit = 0,
    this.perTransactionLimit = 0,

    this.status = '',
    this.verificationStatus = '',
    this.isActive = true,
    this.referenceNumber = '',

    this.tags = const <String>[],
    this.source = '',
    this.priority = '',
    this.assignedTo = '',
    this.totalPaymentsReceived = 0,
    this.paymentCount = 0,
    this.lastPaymentDate,
    this.createdAt,
    this.updatedAt,
  });
}
