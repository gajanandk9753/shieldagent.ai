const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const { nanoid } = require("nanoid");
require("dotenv").config();

const buyerAgentModel = require("../../models/authModels/buyerAgent.model");

async function regsiterBuyerAgent(req, res) {
    try {
        const { name, email, password, budgetLimit } = req.body;

        if (!name || !email || !password || budgetLimit === undefined) {
            return res.status(400).json({
                message: "Please fill all required fields",
                success: false
            });
        }

        const isExisting = await buyerAgentModel.findOne({ email });
        if (isExisting) {
            return res.status(400).json({
                message: "Email is already in use",
                success: false
            });
        }

        const passwordHash = await bcrypt.hash(password, 10);
        const apiKey = `sa_live_${nanoid(15)}`;

        const newAgent = new buyerAgentModel({
            name: name,
            email: email,
            passwordHash: passwordHash,
            role: "buyer-agent",
            apiKey: apiKey,
            budgetLimit: budgetLimit
        });

        await newAgent.save();

        const token = jwt.sign(
            {
                userId: newAgent._id,
                email: email
            },
            process.env.JSON_SECRET,
            {
                expiresIn: '30d'
            }
        );

        return res.status(201).json({
            message: "Buyer agent registered successfully",
            success: true,
            token: token,
            agent: {
                name: newAgent.name,
                email: newAgent.email,
                role: newAgent.role,
                apiKey: newAgent.apiKey,
                budgetLimit: newAgent.budgetLimit,
                status: newAgent.status
            }
        });
    } catch (error) {
        console.error('Error in registering the buyer agent:', error);
        return res.status(500).json({
            message: "Internal Server Error",
            success: false
        });
    }
}

module.exports = {
    regsiterBuyerAgent
};