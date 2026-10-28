// Model for Licence Details (1:1 with Android LicenceDetailResponse & LicenceDetailsFragment)

class LicenceDetailsData {
  final String gstin;
  final String pan;
  final String fssai;
  final bool isAutoInvoice;

  const LicenceDetailsData({
    this.gstin = '',
    this.pan = '',
    this.fssai = '',
    this.isAutoInvoice = false,
  });

  factory LicenceDetailsData.fromJson(Map<String, dynamic> json) {
    final licence = json['licence'] as Map<String, dynamic>? ?? json;
    return LicenceDetailsData(
      gstin: licence['gstin']?.toString() ?? '',
      pan: licence['pan']?.toString() ?? '',
      fssai: licence['fssai']?.toString() ?? '',
      isAutoInvoice: licence['isAutoInvoice'] == true ||
          licence['is_auto_invoice'] == true,
    );
  }
}

class LicenceDetailsState {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final String gstin;
  final String pan;
  final String fssai;
  final bool isAutoInvoice;

  const LicenceDetailsState({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.gstin = '',
    this.pan = '',
    this.fssai = '',
    this.isAutoInvoice = false,
  });

  LicenceDetailsState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    String? gstin,
    String? pan,
    String? fssai,
    bool? isAutoInvoice,
  }) {
    return LicenceDetailsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
      gstin: gstin ?? this.gstin,
      pan: pan ?? this.pan,
      fssai: fssai ?? this.fssai,
      isAutoInvoice: isAutoInvoice ?? this.isAutoInvoice,
    );
  }
}
