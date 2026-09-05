const express = require('express');
const authRoutes = require("./routes/auth.routes");
const buyerAgentRoutes = require("./routes/buyerAgent.routes");
const vendorAgentRoutes = require("./routes/vendorAgent.routes");
const { razorpayWebhook } = require("./controllers/webhook.controller");
const connectDatabase = require("./db/db"); 

const app = express();

app.use(express.json());

app.use(async (req, res, next) => {
    try {
        await connectDatabase();
        next();
    } catch (error) {
        console.error("Database connection failed:", error);
        return res.status(500).json({ message: "Database connection failed" });
    }
});

app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.originalUrl}`);
    next();
});

//auth
app.use("/auth", authRoutes);

// routes of buyer agent
app.use("/buyer-agent", buyerAgentRoutes);

// routes of vendor agent
app.use("/vendor-agent", vendorAgentRoutes);

// receives razorpay webhook
app.post("/webhooks/razorpay", razorpayWebhook);

// health route
app.get("/", (req,res) => {
    return res.status(200).json({
        message : "Health status is good. Server is running..."
    });
});

module.exports = app;