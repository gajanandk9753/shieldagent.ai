// auto approve  buyer agent
const axios = require("axios");

const BUYER_API_KEY = "sa_live_J-fzX1-lXi_WzAr"; 
const VENDOR_ID = "6a9a708399c969886dcfa78f";
const BASE_URL = "http://10.156.124.41:3000";

const api = axios.create({
    baseURL: BASE_URL,
    headers: {
        "x-api-key": BUYER_API_KEY,
        "Content-Type": "application/json"
    }
});

async function executeProcurement() {
    process.stdout.write("\n[SYSTEM] Initializing ProcureBot v2.0 (Happy Path)...\n");

    try {
        process.stdout.write("[NETWORK] Fetching current risk status...\n");
        const statusRes = await api.get("/buyer-agent/get-risk-status");
        
        if (statusRes.data.status === "SUSPENDED") {
            process.stdout.write("[CRITICAL] Agent is suspended. Halting execution.\n");
            return;
        }

        process.stdout.write("[NETWORK] Verifying operational budget...\n");
        const budgetRes = await api.get("/buyer-agent/bot/budget");
        const remainingBudget = budgetRes.data.budgetLimit - budgetRes.data.budgetSpent;
        
        if (remainingBudget <= 0) {
            process.stdout.write("[CRITICAL] Budget depleted. Halting execution.\n");
            return;
        }

        process.stdout.write(`[DATA] Operational budget verified: INR ${remainingBudget}\n`);
        process.stdout.write("[NETWORK] Retrieving vendor catalog...\n");
        
        const catalogRes = await api.get(`/buyer-agent/get-catalog?vendorId=${VENDOR_ID}`);
        const catalog = catalogRes.data.catalog;
        
        if (!catalog || catalog.length === 0) {
            process.stdout.write("[WARN] Vendor catalog is empty. Please add items via the Flutter app.\n");
            return;
        }

        // Target the tech item to ensure AUTO_APPROVE from Gemini
        const targetItem = catalog.find(item => item.name.toLowerCase().includes("esp32")) || catalog[0];
        
        const orderQuantity = 2; 
        const expectedTotal = targetItem.price * orderQuantity;
        
        process.stdout.write(`[DATA] Target identified: ${targetItem.name} | Unit Price: INR ${targetItem.price} | Quantity: ${orderQuantity}\n`);
        process.stdout.write(`[DATA] Calculated total: INR ${expectedTotal}\n`);

        if (expectedTotal > remainingBudget) {
            process.stdout.write("[WARN] Order exceeds remaining budget. Terminating.\n");
            return;
        }

        process.stdout.write("[NETWORK] Requesting ShieldAgent hybrid risk evaluation...\n");
        const evalRes = await api.post("/buyer-agent/orders/evaluate", {
            vendorId: VENDOR_ID,
            itemId: targetItem.itemId,
            quantity: orderQuantity,
            expectedAmount: expectedTotal
        });

        process.stdout.write(`[EVALUATION] Decision: ${evalRes.data.decision} | Risk Score: ${evalRes.data.riskScore}/100\n`);

        if (evalRes.data.decision !== "AUTO_APPROVE") {
            process.stdout.write(`[WARN] Order halted due to decision: ${evalRes.data.decision}\n`);
            return;
        }

        process.stdout.write("[NETWORK] Evaluation passed (AUTO_APPROVE). Committing transaction...\n");
        const orderRes = await api.post("/buyer-agent/orders", {
            evaluationId: evalRes.data.evaluationId,
            totalAmount: expectedTotal
        });

        const transactionId = orderRes.data.transactionId;
        process.stdout.write(`\n[SUCCESS] Transaction successfully committed!\n`);
        process.stdout.write(`>>> TRANSACTION_ID: ${transactionId} <<<\n`);
        process.stdout.write(`[STATE] Current Escrow State: ${orderRes.data.state}\n\n`);
        
        process.stdout.write("[SYSTEM] Entering active escrow monitoring phase...\n");
        
        let isComplete = false;
        let attempts = 0;

        while (!isComplete && attempts < 12) {
            await new Promise(resolve => setTimeout(resolve, 5000));
            
            const statusCheck = await api.get(`/buyer-agent/orders/${transactionId}/status`);
            const currentState = statusCheck.data.state;
            
            process.stdout.write(`[POLL] Transaction ${transactionId} state: ${currentState}\n`);
            
            if (currentState === "BALANCE_RELEASED") {
                isComplete = true;
                process.stdout.write("[SUCCESS] Fulfillment verified. Escrow balance released. Cycle complete.\n");
            } else if (currentState === "FROZEN" || currentState === "CANCELLED") {
                process.stdout.write("[CRITICAL] Anomaly detected mid-flight. Transaction halted by ShieldAgent.\n");
                break;
            }
            
            attempts++;
        }

    } catch (error) {
        const errorMsg = error.response ? JSON.stringify(error.response.data) : error.message;
        process.stdout.write(`[ERROR] Fatal exception: ${errorMsg}\n`);
        process.exit(1);
    }
}

executeProcurement();