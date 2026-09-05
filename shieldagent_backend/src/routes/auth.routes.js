const express = require("express");
const router = express.Router();
const { regsiterVendorAgent} = require("../controllers/authControllers/registerVendor.controller");
const { loginVendorAgent} = require("../controllers/authControllers/loginVendor.controller");
const { regsiterBuyerAgent} = require("../controllers/authControllers/registerBuyer.controller");
const { loginBuyerAgent} = require("../controllers/authControllers/loginBuyer.controller");

// resgiter a vendor
router.post("/register/vendor-agent", regsiterVendorAgent);

//login a vendor
router.post("/login/vendor-agent", loginVendorAgent);

// resgiter a buyer
router.post("/register/buyer-agent", regsiterBuyerAgent);

//login a buyer
router.post("/login/buyer-agent", loginBuyerAgent);

module.exports = router;