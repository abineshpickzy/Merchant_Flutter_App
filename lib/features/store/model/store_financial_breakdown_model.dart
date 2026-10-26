import 'package:equatable/equatable.dart';

/// Data model encapsulating financial sales breakdown from `POST overview/overAllStatus`.
class StoreFinancialBreakdownModel extends Equatable {
  final num onlinePayment;
  final num codPayment;
  final num totalAmount;
  final num serviceFee;
  final num tipAmount;
  final num totalNetSales;
  final num afterServiceFee;
  final num agencyDeliveryFee;
  final num totalDeliveryFee;
  final num agencyCommission;
  final num merchantPayable;
  final num packagingFee;

  const StoreFinancialBreakdownModel({
    this.onlinePayment = 0,
    this.codPayment = 0,
    this.totalAmount = 0,
    this.serviceFee = 0,
    this.tipAmount = 0,
    this.totalNetSales = 0,
    this.afterServiceFee = 0,
    this.agencyDeliveryFee = 0,
    this.totalDeliveryFee = 0,
    this.agencyCommission = 0,
    this.merchantPayable = 0,
    this.packagingFee = 0,
  });

  factory StoreFinancialBreakdownModel.fromJson(Map<String, dynamic> json) {
    num getNum(String key) {
      final val = json[key];
      if (val is num) return val;
      if (val is String) return num.tryParse(val) ?? 0;
      return 0;
    }

    return StoreFinancialBreakdownModel(
      onlinePayment: getNum('online_payment'),
      codPayment: getNum('cod_payment'),
      totalAmount: getNum('total_amount'),
      serviceFee: getNum('service_fee'),
      tipAmount: getNum('tip_amount'),
      totalNetSales: getNum('total_net_sales'),
      afterServiceFee: getNum('after_service_fee'),
      agencyDeliveryFee: getNum('agency_delivery_fee'),
      totalDeliveryFee: getNum('total_delivery_fee'),
      agencyCommission: getNum('agency_commission'),
      merchantPayable: getNum('merchant_payable'),
      packagingFee: getNum('packaging_fee'),
    );
  }

  @override
  List<Object?> get props => [
        onlinePayment,
        codPayment,
        totalAmount,
        serviceFee,
        tipAmount,
        totalNetSales,
        afterServiceFee,
        agencyDeliveryFee,
        totalDeliveryFee,
        agencyCommission,
        merchantPayable,
        packagingFee,
      ];
}
