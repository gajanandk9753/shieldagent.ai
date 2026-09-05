const express = require('express');
const router = express.Router();
const { apiKeyMiddleware } = require('../middlewares/apiKey.middleware');
const { jwtMiddleware } = require("../middlewares/jwt.middleware");
const { getVendorCatalog } = require("../controllers/buyerAgentControllers/getCatalog.controller");
const { evaluateOrder } = require("../controllers/buyerAgentControllers/evaluateOrder.controller");
const { placeOrder } = require("../controllers/buyerAgentControllers/order.controller");
const {getOrderStatus} = require("../controllers/sharedControllers/getOrderStatus.controller");
const { getFrozenOrders, resolveOrder } = require("../controllers/sharedControllers/humanReview.controller");
const { getRiskStatus } = require("../controllers/buyerAgentControllers/getRiskStatus.controller");
const { reactivateAgent } = require("../controllers/buyerAgentControllers/reactivateAgent.controller");
const { getBudget } = require("../controllers/buyerAgentControllers/getBudget.controller");
const { getOrders } = require("../controllers/buyerAgentControllers/getOrders.controller");
const { getAllVendors } = require("../controllers/buyerAgentControllers/getVendors.controller");

//get catalog ( data )
router.get("/get-catalog", apiKeyMiddleware, getVendorCatalog);

router.post("/orders/evaluate", apiKeyMiddleware, evaluateOrder); // evaluate the order

router.post("/orders", apiKeyMiddleware, placeOrder) // place the order

// get the status of orders
router.get("/orders/:id/status", apiKeyMiddleware, getOrderStatus);

// to get the frozen orders
router.get("/orders/frozen", jwtMiddleware, getFrozenOrders);

// to resolve the orders ( either approve or reject the order)
router.post("/orders/:id/resolve", jwtMiddleware, resolveOrder);

// to check the current risk-status ( by the agent itself)
router.get("/get-risk-status", apiKeyMiddleware, getRiskStatus);

// risk status by app ( dahsboard )
router.get("/dashboard/get-risk-status", jwtMiddleware, getRiskStatus);

// to reactivate the agent using the app
router.post("/:id/reactivate", jwtMiddleware, reactivateAgent);

// to get the budget
router.get("/me/budget", jwtMiddleware, getBudget);

router.get("/bot/budget", apiKeyMiddleware, getBudget);

// to get the orders
router.get("/me/orders", jwtMiddleware, getOrders);

router.get("/vendors", apiKeyMiddleware, getAllVendors);
      
module.exports = router;