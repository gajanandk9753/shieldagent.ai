const Transaction = require("../../models/agenticModels/transaction.model");
const AuditLog = require("../../models/agenticModels/auditLog.model");
const { GoogleGenerativeAI } = require("@google/generative-ai");

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

async function verifyWaybill(req, res) {
    try {
        if (req.agentRole !== "vendor-agent") {
            return res.status(403).json({ message: "Forbidden", success: false });
        }

        const transactionId = req.params.id;
        const { imageBase64, mimeType } = req.body;
        const vendor = req.agent;

        if (!imageBase64 || !mimeType) {
            return res.status(400).json({ message: "Missing image data or mimeType", success: false });
        }

        const transaction = await Transaction.findById(transactionId).populate("buyerId");
        if (!transaction) return res.status(404).json({ message: "Transaction not found", success: false });
        
        if (transaction.vendorId.toString() !== vendor._id.toString()) {
            return res.status(403).json({ message: "Unauthorized", success: false });
        }

        if (transaction.state !== "AWAITING_DISPATCH_PROOF" && transaction.state !== "ADVANCE_RELEASED") {
            return res.status(400).json({ message: "Transaction not awaiting dispatch proof", success: false });
        }

        const prompt = `
            You are the visual verification AI for ShieldAgent. Analyze this shipping waybill/receipt.
            
            Expected Context:
            - Buyer Location: ${transaction.buyerId.location || "Bhilai, Chhattisgarh"}
            - Document Date: Must be recent (not older than 7 days)
            
            Determine if this is a legitimate shipping document matching the expected location.
            Respond strictly in valid JSON format with four keys:
            "isValid": boolean (true if the document appears to be a valid dispatch proof for the destination),
            "trackingId": string (extract the tracking number, or null if not found),
            "extractedDestination": string (the city/address found on the document),
            "reason": string (a short 1-sentence explanation of your assessment)
        `;

        const imagePart = {
            inlineData: {
                data: imageBase64,
                mimeType: mimeType
            }
        };

        const model = genAI.getGenerativeModel({ 
            model: "gemini-2.5-flash",
            generationConfig: { responseMimeType: "application/json" }
        });

        const result = await model.generateContent([prompt, imagePart]);
        const aiResponse = JSON.parse(result.response.text());

        if (aiResponse.isValid) {
            if (transaction.escrowMode === "ADAPTIVE") {
                const trancheIndex = transaction.tranches.findIndex(t => t.milestone === "DISPATCH_PROOF");
                if (trancheIndex !== -1 && transaction.tranches[trancheIndex].status !== "RELEASED") {
                    transaction.tranches[trancheIndex].status = "RELEASED";
                    transaction.state = "AWAITING_TRANSIT_SCAN";
                }
            } else {
                transaction.state = "DISPATCH_VERIFIED"; 
            }

            transaction.trackingId = aiResponse.trackingId;
            await transaction.save();

            return res.status(200).json({
                message: "Waybill verified successfully by AI",
                success: true,
                extractedData: aiResponse,
                newState: transaction.state
            });

        } else {
            transaction.state = "FROZEN";
            await transaction.save();

            const auditEntry = new AuditLog({
                transactionId: transaction._id,
                decision: "FROZEN",
                reason: `AI Waybill Verification Failed: ${aiResponse.reason}`,
                riskScore: 85,
                actor: "system"
            });
            await auditEntry.save();

            return res.status(423).json({
                message: "Waybill verification failed. Transaction frozen pending manual review.",
                success: false,
                extractedData: aiResponse,
                newState: transaction.state
            });
        }

    } catch (error) {
        console.error("Error in verifyWaybill:", error);
        return res.status(500).json({ message: "Internal Server Error", success: false });
    }
}

module.exports = { verifyWaybill };