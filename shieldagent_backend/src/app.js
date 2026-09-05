const express = require('express');
const authRoutes = require("./routes/auth.routes");
const buyerAgentRoutes = require("./routes/buyerAgent.routes");
const vendorAgentRoutes = require("./routes/vendorAgent.routes");
const { razorpayWebhook } = require("./controllers/webhook.controller");

const app = express();

app.use(express.json());

//auth
app.use("/auth", authRoutes);

// routes of buyer agent
app.use("/buyer-agent", buyerAgentRoutes);

// routes of vendor agent
app.use("/vendor-agent", vendorAgentRoutes);

// receives razorpay webhook
app.post("/webhooks/razorpay", razorpayWebhook);

module.exports = app;