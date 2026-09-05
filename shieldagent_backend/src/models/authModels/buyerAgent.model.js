const mongoose = require('mongoose');

const flagHistorySchema = new mongoose.Schema({
    at: { 
        type: Date, 
        default: Date.now 
    },
    decision: { 
        type: String, 
        required: true 
    }
}, { _id: false });

const buyerAgentSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true
    },
    email: { 
        type: String, 
        required: true, 
        unique: true,
        trim: true
    },
    passwordHash: { 
        type: String, 
        required: true 
    },
    role: { 
        type: String, 
        default: "buyer-agent" 
    },
    apiKey: { 
        type: String, 
        required: true, 
        unique: true 
    },
    status: { 
        type: String, 
        enum: ['ACTIVE', 'SUSPENDED'], 
        default: 'ACTIVE' 
    },
    budgetLimit: {
        type: Number, 
        required: true, 
        default: 0 
    },
    budgetSpent: {
        type: Number, 
        default: 0 
    },
    flagHistory: [flagHistorySchema]
}, { 
    timestamps: true 
});

module.exports = mongoose.model("BuyerAgent", buyerAgentSchema);