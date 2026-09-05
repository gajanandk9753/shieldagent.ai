const buyerAgentModel = require("../../models/authModels/buyerAgent.model");

async function getBudget(req, res) {
    try {
        const agentId = req.agent ? req.agent._id : req.user.userId;

        const buyer = await buyerAgentModel.findById(agentId);
        if (!buyer) {
            return res.status(404).json({ message: "Buyer not found", success: false });
        }

        const remainingAmt = buyer.budgetLimit - buyer.budgetSpent;
        const remainingPct = buyer.budgetLimit > 0 
            ? (remainingAmt / buyer.budgetLimit) * 100 
            : 0;

        return res.status(200).json({
            success: true,
            budgetLimit: buyer.budgetLimit,
            budgetSpent: buyer.budgetSpent,
            budgetRemainingPct: parseFloat(remainingPct.toFixed(2))
        });
    } catch (error) {
        console.error("Error in getBudget:", error);
        return res.status(500).json({ message: "Internal Server Error", success: false });
    }
}

module.exports = { getBudget };