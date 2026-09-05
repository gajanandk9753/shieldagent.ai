const axios = require("axios");

const VENDOR_API_KEY = "sa_live_K5bfEn5ny-H0A4M";
const TRANSACTION_ID = process.argv[2] || "YOUR_TRANSACTION_ID";
const BASE_URL = "https://shieldagentbackend.vercel.app";

const api = axios.create({
    baseURL: BASE_URL,
    headers: {
        "x-api-key": VENDOR_API_KEY,
        "Content-Type": "application/json"
    }
});

async function executeVendorOperations() {
    process.stdout.write("\n[SYSTEM] Initializing VendorBot v2.0 (Rogue Mode)...\n");

    try {
        if (!TRANSACTION_ID || TRANSACTION_ID === "YOUR_TRANSACTION_ID") {
            process.stdout.write("[ERROR] Missing TRANSACTION_ID. Pass it as an argument: node vendorbot.js <TRANSACTION_ID>\n");
            return;
        }

        process.stdout.write(`[NETWORK] Fetching status for transaction: ${TRANSACTION_ID}...\n`);
        const statusRes = await api.get(`/vendor-agent/orders/${TRANSACTION_ID}/status`);
        let currentState = statusRes.data.state;
        
        process.stdout.write(`[DATA] Current transaction state: ${currentState}\n`);

        if (currentState === "ADVANCE_LOCKED") {
            process.stdout.write("[NETWORK] Attempting to confirm and release advance funds...\n");
            const advanceRes = await api.post(`/vendor-agent/orders/${TRANSACTION_ID}/confirm-advance`);
            currentState = advanceRes.data.state;
            process.stdout.write(`[SUCCESS] Advance released. New state: ${currentState}\n`);
        }

        if (currentState === "ADVANCE_RELEASED") {
            const currentTotal = statusRes.data.advanceAmount + statusRes.data.balanceAmount;
            const maliciousNewAmount = Math.round(currentTotal * 1.40); 
            
            process.stdout.write(`[INTRUSION] Initiating mid-flight price modification.\n`);
            process.stdout.write(`[DATA] Original Total: INR ${currentTotal} | Proposed Total: INR ${maliciousNewAmount}\n`);
            process.stdout.write("[NETWORK] Submitting revised terms to ShieldAgent...\n");

            try {
                // If your backend route is registered as POST, keep api.post; if GET with body, use api.request
                const priceRes = await api.post(`/vendor-agent/orders/${TRANSACTION_ID}/report-price-change`, {
                    newAmount: maliciousNewAmount
                });
                process.stdout.write(`[RESPONSE] ShieldAgent accepted terms. State: ${priceRes.data.state}\n`);
            } catch (err) {
                if (err.response && (err.response.status === 423 || err.response.status === 403)) {
                    process.stdout.write(`\n[SHIELD_INTERCEPT] ShieldAgent blocked the request!\n`);
                    process.stdout.write(`[DATA] Reason: ${err.response.data.audit?.reason || err.response.data.message}\n`);
                    process.stdout.write(`[DATA] Final State: ${err.response.data.state || "FROZEN"}\n`);
                } else {
                    throw err;
                }
            }
        } else {
            process.stdout.write(`[WARN] Transaction is in state '${currentState}' (not in ADVANCE_RELEASED).\n`);
        }

        process.stdout.write("[SYSTEM] VendorBot execution sequence terminated.\n\n");

    } catch (error) {
        const errorMsg = error.response ? JSON.stringify(error.response.data) : error.message;
        process.stdout.write(`[ERROR] Fatal exception: ${errorMsg}\n`);
        process.exit(1);
    }
}

executeVendorOperations();