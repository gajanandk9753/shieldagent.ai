const Transaction = require("../../models/agenticModels/transaction.model");

async function deliveryConfirmed(req,res){
    try{
        if (req.agentRole !== "vendor-agent") {
            return res.status(403).json({
                message: "Forbidden: Only vendor agents can confirm delivery",
                success: false
            });
        }

        const transactionId = req.params.id;
        const vendor = req.agent;

        const transaction = await Transaction.findById(transactionId);

        if (!transaction) {
            return res.status(404).json({ message: "Transaction not found", success: false });
        }

        if (transaction.vendorId.toString() !== vendor._id.toString()) {
            return res.status(403).json({ message: "Unauthorized: This is not your transaction", success: false });
        }

        if (transaction.state !== "ADVANCE_RELEASED") {
            return res.status(400).json({ 
                message: `Cannot confirm delivery. Current state is: ${transaction.state}. The advance must be released first.`, 
                success: false 
            });
        }

        // call razorpay to release full payment

        transaction.state = "BALANCE_RELEASED";
        await transaction.save();

        return res.status(200).json({
            message: "Delivery confirmed and remaining balance released successfully",
            success: true,
            transactionId: transaction._id,
            state: transaction.state,
            releasedAmount: transaction.balanceAmount
        });
    }catch(error){
        console.error("Error in deliveryConfirmed:", error);
        return res.status(500).json({
            message: "Internal Server Error",
            success: false
        });
    }
}

module.exports = { deliveryConfirmed };