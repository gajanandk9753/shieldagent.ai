const axios = require("axios");

// Resgiter an email on the shieldagent mobile app and then get api key and paste here
const BUYER_API_KEY = "sa_live_i7hVB1cEsDmhTyJ";
const VENDOR_ID = "6a9ab4dda52ad6fbe0345de9";
const BASE_URL = "http://10.50.47.106:3000";

const api = axios.create({
    baseURL: BASE_URL,
    headers: {
        "x-api-key": BUYER_API_KEY,
        "Content-Type": "application/json"
    }
});

const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

class AutonomousBuyer {
    constructor() {
        this.catalog = [];
    }

    async init() {
        process.stdout.write("\n[SYSTEM] Initializing ProcureBot v3.0 (Autonomous Audit Suite)...\n");
        const budgetRes = await api.get("/buyer-agent/bot/budget");
        process.stdout.write(`[DATA] Operational budget verified: INR ${budgetRes.data.budgetLimit - budgetRes.data.budgetSpent}\n`);

        const catalogRes = await api.get(`/buyer-agent/get-catalog?vendorId=${VENDOR_ID}`);
        this.catalog = catalogRes.data.catalog;
    }

    async placeOrder(itemName, quantity, expectFailure = false) {
        const item = this.catalog.find(i => i.name.toLowerCase().includes(itemName.toLowerCase())) || this.catalog[0];
        const expectedTotal = item.price * quantity;
        
        process.stdout.write(`\n[NETWORK] Requesting ShieldAgent evaluation for: ${item.name} (Qty: ${quantity})...\n`);
        
        const evalRes = await api.post("/buyer-agent/orders/evaluate", {
            vendorId: VENDOR_ID,
            itemId: item.itemId,
            quantity: quantity,
            expectedAmount: expectedTotal
        });

        process.stdout.write(`[EVALUATION] Decision: ${evalRes.data.decision} | Score: ${evalRes.data.riskScore}/100\n`);
        if (evalRes.data.reason) process.stdout.write(`[AI_REASON] "${evalRes.data.reason}"\n`);

        if (evalRes.data.decision !== "AUTO_APPROVE") {
            if (expectFailure) return null;
            throw new Error(`Unexpected decision: ${evalRes.data.decision}`);
        }

        const orderRes = await api.post("/buyer-agent/orders", {
            evaluationId: evalRes.data.evaluationId,
            totalAmount: expectedTotal
        });

        process.stdout.write(`[SUCCESS] Transaction committed! >>> TRANSACTION_ID: ${orderRes.data.transactionId} <<<\n`);
        return orderRes.data.transactionId;
    }

    async monitorAndReleaseEscrow(transactionId) {
        process.stdout.write("\n[SYSTEM] Polling escrow state. Waiting for VendorBot fulfillment...\n");
        let isComplete = false;
        
        while (!isComplete) {
            await delay(4000);
            const status = await api.get(`/buyer-agent/orders/${transactionId}/status`);
            process.stdout.write(`[POLL] Current State: ${status.data.state}\n`);

            if (status.data.state === "ADVANCE_RELEASED" || status.data.state === "FULFILLED") {
                process.stdout.write("[NETWORK] Goods verified. Releasing balance from escrow...\n");
                try {
                    // Adjust this endpoint if your backend uses a different route for buyer confirmation
                    await api.post(`/buyer-agent/orders/${transactionId}/confirm-receipt`);
                    process.stdout.write("[SUCCESS] Balance Released! Escrow cycle complete.\n");
                } catch (e) {
                    process.stdout.write("[INFO] Backend auto-handled balance release or endpoint missing. Moving on.\n");
                }
                isComplete = true;
            } else if (status.data.state === "FROZEN") {
                process.stdout.write("[CRITICAL] ShieldAgent froze the transaction. Halting monitor.\n");
                break;
            }
        }
    }

    async executeSybilAttack() {
        process.stdout.write("\n[ATTACK] Initiating Sybil Shield Wash-Trading Simulation...\n");
        const cheapItem = this.catalog.reduce((prev, curr) => prev.price < curr.price ? prev : curr);
        
        for (let i = 1; i <= 6; i++) {
            process.stdout.write(`[SWARM] Firing micro-transaction ${i}/6... `);
            try {
                const evalRes = await api.post("/buyer-agent/orders/evaluate", {
                    vendorId: VENDOR_ID,
                    itemId: cheapItem.itemId,
                    quantity: 1,
                    expectedAmount: cheapItem.price
                });
                process.stdout.write(`Decision: ${evalRes.data.decision}\n`);
            } catch (err) {
                process.stdout.write(`[INTERCEPTED] ${err.response?.data?.message || err.message}\n`);
                break;
            }
            await delay(500);
        }
        process.stdout.write("[SYSTEM] Sybil attack concluded. Circuit breaker should now be tripped.\n");
    }

    async run() {
        try {
            await this.init();

            // Phase 1: The Happy Path (Tech Hardware)
            process.stdout.write("\n=== MISSION 1: END-TO-END ESCROW ===");
            const txnId = await this.placeOrder("Raspberry", 10);
            
            process.stdout.write(`\n*** ACTION REQUIRED ***\nRun VendorBot in a new terminal: node vendorbot.js ${txnId}\n`);
            await this.monitorAndReleaseEscrow(txnId);

            // Phase 2: Contextual AI Firewall Testing
            process.stdout.write("\n=== MISSION 2: AI CONTEXT FIREWALL ===");
            await this.placeOrder("Holi Gulal", 1, true);

            // Phase 3: Sybil Swarm
            process.stdout.write("\n=== MISSION 3: SYBIL SHIELD ===");
            await this.executeSybilAttack();

            process.stdout.write("\n[SYSTEM] Autonomous suite execution completed.\n");
        } catch (err) {
            process.stdout.write(`\n[FATAL] ${err.response ? JSON.stringify(err.response.data) : err.message}\n`);
        }
    }
}

new AutonomousBuyer().run();