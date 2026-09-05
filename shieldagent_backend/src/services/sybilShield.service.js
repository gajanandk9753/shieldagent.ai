const Transaction = require("../models/agenticModels/transaction.model");

async function detectCollusion(buyerId, vendorId) {
    try {
        const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);

        const microOrders = await Transaction.countDocuments({
            buyerId: buyerId,
            vendorId: vendorId,
            totalAmount: { $lt: 100 },
            createdAt: { $gte: oneHourAgo }
        });

        if (microOrders >= 5) {
            return { 
                isColluding: true, 
                reason: "Sybil Threat: Rapid micro-transaction loop detected between buyer and vendor." 
            };
        }

        const totalBuyerOrders = await Transaction.countDocuments({ buyerId: buyerId });
        
        if (totalBuyerOrders > 10) {
            const pairOrders = await Transaction.countDocuments({ 
                buyerId: buyerId, 
                vendorId: vendorId 
            });
            
            const pairPercentage = pairOrders / totalBuyerOrders;

            if (pairPercentage > 0.80) {
                return { 
                    isColluding: true, 
                    reason: "Sybil Threat: Wash-trading monopolization. Buyer routing >80% of volume to a single vendor." 
                };
            }
        }

        return { isColluding: false };

    } catch (error) {
        console.error("Error in Sybil Shield:", error);
        return { isColluding: false };
    }
}

module.exports = { detectCollusion };