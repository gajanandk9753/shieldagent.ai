const mongoose = require("mongoose");
const Razorpay = require("razorpay");
require('dotenv').config();
const Evaluation = require("../../models/agenticModels/evaluation.model");
const Transaction = require("../../models/agenticModels/transaction.model");

const razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET,
});

async function placeOrder(req, res) {
    try {
        if (req.agentRole !== "buyer-agent") {
            return res.status(403).json({
                message: "Forbidden",
                success: false
            });
        }

        const { evaluationId, totalAmount } = req.body;
        const buyer = req.agent;

        if (!evaluationId || totalAmount === undefined) {
            return res.status(400).json({
                message: "Missing required fields",
                success: false
            });
        }

        const evaluation = await Evaluation.findById(evaluationId);

        if (!evaluation) {
            return res.status(404).json({ message: "Evaluation not found", success: false });
        }

        if (evaluation.buyerId.toString() !== buyer._id.toString()) {
            return res.status(403).json({ message: "Unauthorized evaluation access", success: false });
        }

        if (evaluation.consumed) {
            return res.status(400).json({ message: "Evaluation has already been consumed", success: false });
        }

        if (new Date() > evaluation.expiresAt) {
            return res.status(400).json({ message: "Evaluation has expired", success: false });
        }

        if (evaluation.decision !== "AUTO_APPROVE") {
            return res.status(403).json({ 
                message: "Cannot proceed. Evaluation decision requires permission or is blocked.", 
                success: false 
            });
        }

        const advanceAmount = Number(totalAmount) * (evaluation.escrowPlan.advancePct / 100);
        const balanceAmount = Number(totalAmount) - advanceAmount;

        const razorpayOptions = {
            amount : Math.round(advanceAmount * 100),
            currency : "INR",
            receipt : `rcpt_${evaluationId.toString().slice(-10)}`
        }

        const razorpayOrder = await razorpay.orders.create(razorpayOptions);

        evaluation.consumed = true;
        await evaluation.save();

        buyer.budgetSpent += Number(totalAmount);
        await buyer.save();

        const newTransaction = new Transaction({
            buyerId: buyer._id,
            vendorId: evaluation.vendorId,
            evaluationId: evaluation._id,
            state: "ADVANCE_LOCKED",
            advanceAmount: advanceAmount,
            balanceAmount: balanceAmount,
            razorpayOrderId: razorpayOrder.id
        });

        await newTransaction.save();

        return res.status(201).json({
            message: "Order placed and advance locked successfully",
            success: true,
            transactionId: newTransaction._id, // will be sent back to get advance released
            state: newTransaction.state,
            advanceAmount: newTransaction.advanceAmount,
            balanceAmount: newTransaction.balanceAmount,
            razorpayOrderId: newTransaction.razorpayOrderId
        });

    } catch (error) {
        console.error("Error in placeOrder:", error);
        return res.status(500).json({
            message: "Internal Server Error",
            success: false
        });
    }
}

module.exports = { placeOrder };