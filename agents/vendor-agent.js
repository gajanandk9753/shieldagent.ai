const axios = require("axios");

// Resgiter an email on the shieldagent mobile app and then get api key and paste here
const VENDOR_API_KEY = "sa_live_I7HMJD_eu5aG-e_";
const TRANSACTION_ID = process.argv[2];
const BASE_URL = "http://10.50.47.106:3000";

if (!TRANSACTION_ID) {
    console.log("[ERROR] Provide a Transaction ID: node vendorbot.js <TRANSACTION_ID>");
    process.exit(1);
}

const api = axios.create({
    baseURL: BASE_URL,
    headers: {
        "x-api-key": VENDOR_API_KEY,
        "Content-Type": "application/json"
    }
});

const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function executeFulfillmentAndAttack() {
    process.stdout.write(`\n[SYSTEM] VendorBot v3.0 attaching to Transaction: ${TRANSACTION_ID}\n`);

    try {
        const statusRes = await api.get(`/vendor-agent/orders/${TRANSACTION_ID}/status`);
        let state = statusRes.data.state;
        const totalValue = statusRes.data.advanceAmount + statusRes.data.balanceAmount;
        
        process.stdout.write(`[DATA] Current State: ${state} | Total Value: INR ${totalValue}\n`);

        if (state === "ADVANCE_LOCKED") {
            process.stdout.write("\n[NETWORK] Confirming Razorpay advance payment...\n");
            const advanceRes = await api.post(`/vendor-agent/orders/${TRANSACTION_ID}/confirm-advance`);
            state = advanceRes.data.state;
            process.stdout.write(`[SUCCESS] Funds secured. New State: ${state}\n`);
        }

        // The Malicious Mid-Flight Price Hike
        process.stdout.write("\n[ATTACK] Attempting unauthorized mid-flight price modification...\n");
        const maliciousAmount = Math.round(totalValue * 1.50);
        
        try {
            await api.post(`/vendor-agent/orders/${TRANSACTION_ID}/report-price-change`, {
                newAmount: maliciousAmount
            });
        } catch (err) {
            process.stdout.write(`[SHIELD_INTERCEPT] 423 Locked! ShieldAgent blocked the tamper attempt.\n`);
            if (err.response?.data?.audit) {
                process.stdout.write(`[DATA] Firewall Reason: ${err.response.data.audit.reason}\n`);
            }
        }

        await delay(2000);

        // Logistics & Fulfillment
        process.stdout.write("\n[NETWORK] Dispatching goods and updating logistics...\n");
        try {
            const logisticsRes = await api.post(`/vendor-agent/orders/${TRANSACTION_ID}/logistics-update`, { delayInDays: 0 });
            process.stdout.write(`[SUCCESS] Logistics updated. State is now ready for buyer release.\n`);
        } catch (e) {
            process.stdout.write(`[INFO] Logistics update skipped or blocked due to earlier freeze.\n`);
        }

        process.stdout.write("\n[SYSTEM] Vendor operations concluded. Check Buyer terminal.\n\n");

    } catch (error) {
        const errorMsg = error.response ? JSON.stringify(error.response.data) : error.message;
        process.stdout.write(`\n[ERROR] Fatal exception: ${errorMsg}\n`);
    }
}

executeFulfillmentAndAttack();