const mongoose = require("mongoose");

const transactionSchema = new mongoose.Schema({
    buyerId : {
        type : mongoose.Schema.Types.ObjectId,
        ref : "BuyerAgent",
        required : true
    },
    vendorId : {
        type : mongoose.Schema.Types.ObjectId,
        ref : "VendorAgent",
        required : true
    },
    evaluationId : {
        type : mongoose.Schema.Types.ObjectId,
        ref : "Evaluation",
        required : true,
        unique : true
    },
    state : {
        type : String,
        enum: ['ADVANCE_LOCKED', 'ADVANCE_RELEASED', 'BALANCE_RELEASED', 'FROZEN', 'CANCELLED'],
        required: true
    },
    advanceAmount: {
        type: Number,
        required: true
    },
    balanceAmount: {
        type: Number,
        required: true
    },
    razorpayOrderId: {
        type: String,
        required: true
    },
    escrowMode: {
    type: String,
    enum: ["STANDARD", "ADAPTIVE"],
    default: "STANDARD"
    },
    tranches: [{
        milestone: { type: String, required: true },
        amount: { type: Number, required: true },
        status: { type: String, enum: ["PENDING", "RELEASED"], default: "PENDING" }
    }],
    logisticsFlags: {
        type: Number,
        default: 0
    }
}, {
    timestamps : true
});

module.exports = mongoose.model("Transaction", transactionSchema);