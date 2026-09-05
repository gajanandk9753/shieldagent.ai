
class ApiConstants {
  ApiConstants._();
  static const String baseUrl = "https://shieldagentbackend.vercel.app";

  static const String registerVendor = "/auth/register/vendor-agent";
  static const String loginVendor = "/auth/login/vendor-agent";
  static const String registerBuyer = "/auth/register/buyer-agent";
  static const String loginBuyer = "/auth/login/buyer-agent";

  static const String buyerCatalog = "/buyer-agent/get-catalog";
  static const String buyerEvaluate = "/buyer-agent/orders/evaluate";
  static const String buyerPlaceOrder = "/buyer-agent/orders";
  static String buyerOrderStatus(String id) =>
      "/buyer-agent/orders/$id/status";
  static const String buyerRiskStatus = "/buyer-agent/get-risk-status";

  static const String buyerFrozenOrders = "/buyer-agent/orders/frozen";
  static String buyerResolveOrder(String id) =>
      "/buyer-agent/orders/$id/resolve";
  static const String buyerDashboardRiskStatus =
      "/buyer-agent/dashboard/get-risk-status";
  static String buyerReactivate(String id) => "/buyer-agent/$id/reactivate";
  static const String buyerBudget = "/buyer-agent/me/budget";
  static const String buyerOrders = "/buyer-agent/me/orders";

  static const String vendorSaveCatalog = "/vendor-agent/save-catalog";
  static String vendorConfirmAdvance(String id) =>
      "/vendor-agent/orders/$id/confirm-advance";
  static String vendorDeliveryConfirmed(String id) =>
      "/vendor-agent/orders/$id/delivery-confirmed";
  static String vendorOrderStatus(String id) =>
      "/vendor-agent/orders/$id/status";
  static String vendorReportPriceChange(String id) =>
      "/vendor-agent/orders/$id/report-price-change";

  static String vendorClaimTranche(String id) =>
      "/vendor-agent/orders/$id/claim-tranche";
  static String vendorVerifyWaybill(String id) =>
      "/vendor-agent/orders/$id/verify-waybill";

  static const String vendorFrozenOrders = "/vendor-agent/orders/frozen";
  static String vendorResolveOrder(String id) =>
      "/vendor-agent/orders/$id/resolve";

  static const String vendorGetCatalog = "/vendor-agent/catalog";
  static const String vendorOrders = "/vendor-agent/me/orders";
  static const String buyerVendors = "/buyer-agent/vendors";
}
