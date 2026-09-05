const express = require('express');
const router = express.Router();
const {apiKeyMiddleware} = require("../middlewares/apiKey.middleware");
const { jwtMiddleware } = require("../middlewares/jwt.middleware");
const {saveVendorCatalog} = require("../controllers/vendorAgentControllers/saveCatalog.controller");
const { confirmAdvance } = require("../controllers/vendorAgentControllers/confirmAdvance.controller");
const { deliveryConfirmed } = require("../controllers/vendorAgentControllers/deliveryConfirmed.controller");
const {getOrderStatus} = require("../controllers/sharedControllers/getOrderStatus.controller");
const { reportPriceChange } = require("../controllers/vendorAgentControllers/reportPriceChange.controller");
const { getFrozenOrders, resolveOrder } = require("../controllers/sharedControllers/humanReview.controller");
const { reportLogisticsUpdate } = require("../controllers/vendorAgentControllers/logisticsUpdate.controller");
const { claimTranche } = require("../controllers/vendorAgentControllers/claimTranche.controller");
const { verifyWaybill } = require("../controllers/vendorAgentControllers/verifyWaybill.controller");
const { getVendorCatalog } = require("../controllers/vendorAgentControllers/getCatalog.controller");
const { getVendorOrders } = require("../controllers/vendorAgentControllers/getOrders.controller");

// use to register catalog of vendor
router.post("/save-catalog", apiKeyMiddleware, saveVendorCatalog);

router.get("/catalog", apiKeyMiddleware, getVendorCatalog);

// to release the advance payment
router.post("/orders/:id/confirm-advance", apiKeyMiddleware, confirmAdvance);

// to update the delivery status as confirmation
router.post("/orders/:id/delivery-confirmed", apiKeyMiddleware, deliveryConfirmed);

// to get the status of order
router.get("/orders/:id/status", apiKeyMiddleware, getOrderStatus);

// to report the change in the price in the mid of a order
router.get("/orders/:id/report-price-change", apiKeyMiddleware, reportPriceChange);

// to get the frozen orders
router.get("/orders/frozen", jwtMiddleware, getFrozenOrders);

// to resolve the orders ( either approve or reject the order)
router.post("/orders/:id/resolve", jwtMiddleware, resolveOrder);

router.post("/orders/:id/logistics-update", apiKeyMiddleware, reportLogisticsUpdate);
router.post("/orders/:id/claim-tranche", apiKeyMiddleware, claimTranche);
router.post("/orders/:id/verify-waybill", apiKeyMiddleware, verifyWaybill);

router.get("/me/orders", apiKeyMiddleware, getVendorOrders);

module.exports = router;